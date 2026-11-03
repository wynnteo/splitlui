# Phase 5 — Common Fund refunds and corrections

## Required one-time Supabase setup
After merging the PR, open your Supabase project → **SQL Editor**.
Run `supabase/migrations/20261103_000004_fund_refunds_corrections.sql`
only **after** the Phase 4 Common Fund migration
(`20261103_000003_trip_common_fund.sql`).

The GitHub merge does not apply SQL automatically. The migration retains
existing fund balances and transactions.

In Android Studio terminal:

    git checkout master
    git pull origin master
    flutter pub get
    flutter gen-l10n
    flutter analyze

Then use Android Studio's normal Run button.

## New features
- **Refund a member:** group organiser records money that was actually
  returned to that member. Choose recipient, amount and note. The fund
  balance goes down and the entry remains visible.
- **Correct an entry:** organiser taps an original contribution, expense,
  or refund and supplies a reason. The database writes a compensating
  **reversal** and adjusts the balance, preserving original history.
- Entries can only be reversed **once**. Reversal entries cannot themselves
  be reversed. Reversing a contribution fails if the account doesn't have
  enough money to remove it.
- Only group organisers can refund or reverse.
- Fund-only transactions do not create ordinary individual expense shares.

## Example
Alice and Bob contribute JPY 30,000 each: fund balance JPY 60,000.
Pay JPY 9,000 using the fund: balance JPY 51,000.

Refund Alice JPY 20,000 *after handing that amount back*: balance JPY 31,000.
Refund Bob JPY 20,000: balance JPY 11,000.

If the ¥9,000 dinner was recorded by mistake, tap that entry,
choose **Correct this entry**, and write the reason.
The app logs a +¥9,000 reversal and the balance becomes ¥20,000.
The erroneous dinner remains visible, marked **Reversed**.

## Important limitations
- This is **manual accounting only**, not a payment service. Recording a
  refund does not send money.
- There is no automatic fair refund calculation, proportional ownership
  tracking, or trip-close reconciliation. The group must agree on the
  refund amounts and ensure they match actual cash returned.
- A normal refund and a correction are different: refund = money leaves
  the pooled cash; reversal = correct an incorrect bookkeeping record.
- No offline writes or server idempotency keys in this phase. Do not
  repeatedly submit if the network response is ambiguous; refresh the
  history first.
- Anonymous sign-in still ties identity to a device/session. Recoverable
  accounts, audit review, and financial reconciliation should be implemented
  before public release.
- Only the **Common Fund** ledger can be corrected in this PR; ordinary
  Shared Expense entries are unchanged.

## Tests
1. Check existing Phase 4 data survives migration unchanged.
2. Refund amount less than or equal to balance succeeds; a larger refund
   fails without changing balance/history.
3. A non-owner session cannot call the refund/reversal RPCs.
4. Reverse each entry type and check balance adjustments and audit trail.
5. Attempt to reverse the same entry twice, and reverse a reversal.
   Both should fail without duplicate accounting.
6. Reverse a contribution that would make the balance negative.
   It must fail atomically.
7. Test two simultaneous requests against the same balance.
8. Test English/Chinese, light/dark mode, and different screen widths.

**Validation status:** Flutter tooling and the actual Supabase migration
have not been executed in the GitHub editing environment. Review before
merging, then run the above tests on your own Supabase test group.
