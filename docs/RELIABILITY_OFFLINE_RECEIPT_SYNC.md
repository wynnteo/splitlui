# Reliability polish — existing expense and receipt workflows

This is intentionally a **maintenance PR**, not a new feature or a new
screen. No database migration, design overhaul, currency logic or new package.

## Fixed behaviours

1. **Receipt upload failure no longer blocks later confirmed expenses.**
   Pending financial writes still process in order, using the existing
   server-side idempotency UUID. Once a specific expense has a confirmed
   server UUID, its photo can fail without preventing later expenses
   from syncing. Its queue record remains visible as **receipt pending**.

2. **Retry only the photo.** If an expense has a saved remote ID, the
   outbox never calls the financial-create RPC again for it. It first
   looks for an existing photo mapping (important when the server
   succeeded but the response was lost), then uploads only if needed.

3. **Never delete a potentially attached image.** Previously,
   `ReceiptStorage.upload` immediately removed the newly uploaded Storage
   object if the attachment RPC threw. A lost acknowledgement could
   leave a persisted mapping pointing at a deleted image. Now it checks
   whether the object was linked and preserves ambiguous objects for
   later reconciliation. This favours financial/receipt integrity, with
   the trade-off that an orphan Storage object may remain after a real
   failure; orphan cleanup needs a separate controlled maintenance flow.

4. **Clear recovery actions.** Tap a pending row in Expenses to see
   **Sync now**. If the financial expense is already confirmed but the
   photo remains stuck, choose **Skip photo** after confirmation. This
   deletes *only* the local retry/photo copy and does not alter any
   expense, member split, Common Fund or repayment.

5. **More accurate copy.** If all queued items are already-confirmed
   expenses awaiting images, the title changes to **Receipt photos
   waiting to upload** rather than implying the expenses themselves
   have not synced.

6. **Per-group concurrency guard and account change guard.** Multiple
   windows of the same group do not attempt overlapping replay, while
   unrelated groups can sync independently. Processing stops when the
   signed-in user changes.

## What stays the same

- Offline expenses are saved to SQLite before network access.
- Server-side `add_trip_expense_offline` remains the only transaction
  creator and handles repeat operation UUIDs idempotently.
- Pooled-money debits, refund confirmation and repayments remain online.
- Failed financial creates are **not discarded** or silently skipped:
  they remain in the outbox for a safe retry/owner review.
- Pending money does not show as confirmed group balance.

## Test checklist

```sh
flutter pub get
flutter gen-l10n
flutter analyze
flutter test test/offline_sync_policy_test.dart
flutter test
flutter build apk --release
```

On a device with an authenticated two-member group:

1. Add expense A with receipt, B without receipt, C with receipt offline.
   Reconnect while the Storage bucket is unavailable. Verify A is
   confirmed exactly once, B and C are **also** confirmed, and A/C
   remain marked as photo pending.
2. Re-enable Storage access and tap Sync now: confirm each photo is
   attached once; the queue clears. Verify member balances do not
   change again on receipt retry.
3. Simulate lost response after successful attachment: confirm a second
   retry finds the mapping rather than deleting/uploading the photo.
4. With a confirmed expense whose local JPEG file has been removed,
   open its pending row, choose Skip photo and confirm. Its expense
   and ledger remain in Supabase; only the local photo retry clears.
5. Fail financial creation before server confirmation: the queued item
   remains; it must not be discarded as a photo-only failure.
6. Switch user accounts after queueing on account A: account B must not
   see or replay account A's pending financial records.
7. Open two groups while one has a pending receipt: the first group
   should not prevent the other group's sync from running.
8. Test labels in English and Chinese, dark/light modes and narrow
   phone screens.

**Limitations:** Source checks and test code were added, but device
tests and Flutter compilation have not been performed in this editing
environment. The current design still needs an account recovery flow,
a safe permanent-error review workflow and a Storage orphan audit.
