# Expense detail and Common Fund correction improvements

## UI fixes

- The **Group Detail** screen already displays the group name in the
  app bar; the duplicate large group-name heading in the content is removed.
- The **Expenses** screen similarly removes the extra group-name header.
- Tapping an existing Common Fund purchase (for example **Mask**)
  now opens a detailed, scrollable bottom sheet rather than a nearly
  blank slide-up sheet. It displays:
  - Description and **Paid using group funds**
  - Original amount and actual currency
  - Group-currency equivalent and fixed exchange rate (if different)
  - Receipt date (if recorded)
  - Linked private receipt preview (if attached)
  - **Edit expense** / **Delete expense** near the top if the current
    member originally recorded it
- Personal shared expenses already had Edit/Delete. Their action buttons
  are moved ahead of the receipt image, making them easier to find.
- Members other than the creator see the expense details but cannot mutate
  the financial transaction.

## Common Fund edits and deletes

**Required migration:** apply
`supabase/migrations/20261103_000016_fund_expense_corrections.sql`
after 000015, **before** running an updated APK.

The migration introduces a restricted
`correct_trip_fund_purchase` RPC, optimistic `updated_at` conflict
protection, and a permanent `trip_fund_corrections` audit table.
The RPC locks the fund account and validates membership, original
recorder, positive amounts and allowed conversion rates.

For example, an original THB 500 purchase that debited the fund by
THB 500 and is edited to THB 450 **returns THB 50** to the pooled balance.
A purchase changed from THB 500 to THB 600 **debits another THB 100**,
but only if the fund has enough remaining money. Deleting it
**restores THB 500** (or the latest confirmed debit if edited).

This does not create a personal shared expense or member split. It is
a correction to the pooled fund ledger only.

The receipt metadata cascades away after delete, with best-effort
private Storage cleanup. If cleanup fails, the app warns the user.
The audit history remains available to group members but is not yet
displayed in a dedicated UI screen.

## How to edit or delete

1. Open **Group → Expenses**.
2. Tap the existing expense, e.g. **Mask**.
3. Under the amount, select **Edit expense** or **Delete expense**.
   These appear for the member who originally recorded the purchase.
4. For an edit, change the description, original amount, currency,
   rate or receipt date, then Save Changes.
5. For delete, confirm the dialog describing the fund refund.

For personal member-paid expenses the same screen already supports
Edit/Delete, but the server blocks those changes while there are
active confirmed repayments in the group. Common Fund purchases use a
separate, locked-account correction RPC.

## Verification

```bash
flutter pub get
flutter gen-l10n
flutter analyze
flutter build apk --release
```

Test with two group members:
- Original author sees Edit/Delete; other member does not.
- Ordinary personal expense buttons are visible before the receipt.
- A 500→450 fund edit restores 50, a 500→600 edit debits 100,
  and a delete restores the currently recorded debit.
- An edit that would cause a negative fund balance is rejected without
  changing the existing record.
- Two-device stale edits are rejected.
- Record a receipt photo/date; edit retains the image, delete removes
  its mapping and attempts private object cleanup.
- Offline saved member expenses remain unchanged, and pooled purchases
  cannot be corrected without an internet connection.
- Reopen Common Fund page and verify its updated balance.

The code has not been compiled locally or tested against a live
Supabase instance by the assistant. Keep the PR draft until the SQL
and device tests pass.
