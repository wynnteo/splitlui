# Flexible split enhancement — existing Add/Edit Expense

## Scope and UX

The existing Add Expense and Edit Expense screens now include four splitting
modes: **Equal**, **Amount**, **Percent**, **Shares**.

- Equal is the default for new expenses. The previous checkbox selection
  of participating members still works.
- Amount: enter how much of the original receipt each selected participant
  owes (e.g. THB 300, THB 200, THB 500).
- Percent: enter percentages totalling exactly 100.
- Shares: weight people with e.g. 2, 1, 1 (couple = two shares).
- The live preview shows original-currency allocations, after deterministic
  cent rounding, and blocks an invalid total.
- Existing expenses open their historical allocations as **Amount**.
  This preserves their values and avoids guessing the split mode chosen
  on a previous device.
- Fund-paid purchases do not use participant splits and are unchanged.

## Backend invariants

Apply migration **after** 000018:

    supabase/migrations/20261103_000019_flexible_expense_splits.sql

New restricted RPCs:

- `add_trip_expense_offline_custom` — retries by the immutable existing
  client operation UUID, storing participant IDs and exact share amounts.
- `edit_trip_expense_custom` — delegates all existing edit protections
  (creator-only, group membership, stale timestamp checks and blocked
  edits after confirmed repayments) before applying exact shares.
- Internal `_apply_trip_custom_shares` — no app-facing EXECUTE grant.

The backend requires unique current group members, nonnegative two-decimal
shares, at most 50 participants and exact equality with the total bill.
Converted-currency shares use the largest remainder method so the sum of
each participant's converted share equals the stored converted bill total
to the cent. No new table fields or direct client writes.

**Older APK compatibility:** the old equal-split add/edit RPCs remain
available. Local SQLite upgrades from v1 to v2 and adds a nullable
`share_amounts_json` column. Older already-queued expenses without the
new column use the existing legacy offline RPC and keep their immutable
operation UUIDs.

## Examples

- THB 100 split equally three ways: 33.34, 33.33, 33.33.
- THB 100, weighted 2:1:1: 50.00, 25.00, 25.00.
- THB 101 split 50% / 25% / 25%: 50.50, 25.25, 25.25.
- SGD 135 by exact amounts: SGD 100 + 30 + 5.

## Testing checklist

```bash
flutter pub get
flutter gen-l10n
flutter analyze
flutter test test/split_allocation_test.dart
flutter test
flutter build apk --release
```

- Verify each mode with two, three and four members.
- Change the participant selection and recheck the allocation preview.
- Enter a percentage total of 99.99% and ensure Save refuses it.
- Enter exact amounts below the bill total and ensure Save refuses it.
- Edit an existing equal-split expense: it opens with the original
  exact member amounts and does not silently change balances.
- Reopen a newly created weighted-split expense and verify every
  member's original and group-currency shares.
- Change the expense currency and rate, then confirm original and
  converted shares both total exactly.
- With any active confirmed repayment, edits must remain blocked.
- Create a custom split offline, close and reopen the app, reconnect,
  retry sync twice and confirm only one expense exists.
- Upgrade a phone with *older queued equal-split expenses* from the
  v1 SQLite schema; verify they still sync with the original operation IDs.
- Confirm Common Fund purchase, refund and repayment screens are unchanged.

## Notes

This is an existing-feature improvement, not a new navigation area.
It requires a Supabase migration and real device/SQL testing before
production deployment. The assistant's source checks cannot replace a
Flutter build or integration test.
