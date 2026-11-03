# Phase 2 — Offline-first travel expenses (plus teal visual polish)

## Offline features implemented

- When a previously signed-in user has visited a group online, its
  group metadata and member list are cached locally per authenticated user.
  Users can open that group after app restart without a working connection.
- Recently synced shared expenses are cached on-device. **Offline cached
  rows are read-only** because shares, receipt downloads and version checks
  are server-owned. They carry a warning that balances may be stale.
- New **member-paid shared expenses** (including receipt images, currencies,
  FX rate, selected participants and receipt date) are stored first in
  private SQLite + persistent local receipt files.
- The expense list immediately shows a separate *Waiting to sync* area;
  pending rows are never counted as confirmed member balances.
- On returning to the Expenses page, tapping Sync, or regaining connectivity
  while the Expenses screen is open, the app attempts to sync.
- Server-side `add_trip_expense_offline` serialises writes per group,
  validates them through the existing `add_trip_expense_v2` RPC and uses a
  stable client UUID for idempotent retries. Receiving a response is not
  necessary for exactly-once accounting.
- Server idempotency records survive deletion by using a nullable FK, so
  an old retry cannot resurrect an intentionally deleted expense.
- After creating a confirmed server expense, the outbox saves the server
  expense UUID, then uploads the attached receipt. A lost receipt response
  is retried after checking whether its metadata already exists.
- SQLite outbox data and private receipt files survive app termination,
  reboot and network drop. Entries are partitioned by Supabase user id.

## What is NOT offline yet

- Common Fund contributions/withdrawals, repayment confirmations and
  reversals remain online-only, because they require live, locked ledger
  and identity validation.
- Editing/deleting previously synced expenses requires a connection,
  using Phase 20 optimistic `updated_at` checks; conflicting stale edits
  are rejected by the existing backend.
- Pending offline creates are intentionally **immutable** after pressing
  Save. Editing/removing an ambiguous pending request after a lost network
  response could recreate or silently omit money, so no local edit/delete
  action is shown.
- No periodic background service while the app is closed. Sync happens
  when the user returns to Expenses, on its connectivity event, or manually.
- Cached expenses show basic amount/payer information; detailed share
  breakdown and receipt downloads still require internet. Server balances
  always take priority after reconnection.
- A group must have been opened **at least once online** with the current
  authenticated identity to be available offline. An expired or lost
  anonymous login cannot be restored with an offline cache.
- Conflict resolution for simultaneous *offline edits* is not supported;
  edits are deliberately online-only in this phase.

## SQL migration — REQUIRED

Apply AFTER `20261103_000014_expense_edit_delete.sql`:

    supabase/migrations/20261103_000015_offline_expense_outbox.sql

This installs `trip_expense_operations` and the protected
`add_trip_expense_offline` RPC with a stable UUID, immutable payload
verification, group lock, and deleted-operation tombstones. No direct
table INSERT/UPDATE privileges are granted to mobile clients.

## Dependencies and UI

Adds `sqflite`, `path_provider`, `path`, `uuid`,
`connectivity_plus`. The UI palette was changed from a generic blue
accent to **teal** in `lib/ui/lui_style.dart`. This affects
Material primary actions and feature-tile icons in both themes; it
does not regenerate or recolour launcher image assets.

## Release validation

    flutter pub get
    flutter gen-l10n
    flutter analyze
    flutter test
    flutter build apk --release

Test with a real Android phone and at least two group accounts:

1. Sign in and open a group with 3 members while online.
2. Go to Airplane mode, force-close/restart the app, reopen the cached
   group, and add a THB expense with a JPEG receipt and date.
3. Verify the new transaction remains in Waiting to sync after restart,
   and old cached expenses show a stale/offline banner.
4. Return to Wi-Fi. Confirm only **one** expense and the correct equal
   shares appear for all members.
5. With unstable network, repeat sync after server succeeds but before
   the client receives its response; verify exactly one expense.
6. Upload a receipt under broken connectivity, reconnect and retry.
   Verify exactly one linked private receipt; no public download URL.
7. Edit a synced expense from two devices. The stale writer must be
   rejected; do not overwrite the newer version.
8. Delete a synced expense, then resend its old operation ID. The
   server must reject the deleted operation, never recreate it.
9. Confirm Common Fund spending and repayments do not show a fake
   offline-success confirmation and still require the server.
10. Sign into a different anonymous/account identity on the same phone:
    old groups, pending expenses and receipts must not appear.
11. Test Android back navigation, long group/merchant names, English
    and Chinese, light/dark modes, and small-screen layout.

**Important:** Pending expenses are stored in app-private files but not
end-to-end encrypted at rest. Do not clear app data or uninstall before
syncing: Android may delete all pending local records. Account recovery
is a separate launch-readiness requirement.

The connector environment has no Flutter SDK or live Supabase database.
Source checks can be performed here, but the build, migration and
multi-device scenarios above must be run before merging this draft.
