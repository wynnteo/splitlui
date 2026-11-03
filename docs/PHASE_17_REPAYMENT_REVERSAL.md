# Phase 17 — Correct an incorrectly confirmed repayment

The recipient who confirmed a repayment can now undo that confirmation.
This is **a reversal of the app's accounting entry**, not a bank refund.

## Flow

1. Open **Who owes whom → Confirmed repayments**.
2. As the receipt's recipient, select **Undo confirmation**.
3. Enter a reason (3–120 characters), then confirm.
4. The original receipt remains in history, visibly marked **Reversed**
   with the reason. The outstanding member balances and suggested
   repayments recalculate without the reversed receipt.

Other group members can read the reversal history but cannot reverse a
receipt they did not receive. The backend locks the group during reversal
and only allows it once per receipt. Previous confirmation dates, actual
payment currency, original amount, and conversion are preserved.

## Required Supabase SQL migration

Run the migration **after** the Phase 16 SGD/MYR receipts migration:

    supabase/migrations/20261103_000011_repayment_reversals.sql

The additive migration introduces reversible status and audit fields,
updates the protected repayment RPC so outstanding-debt checks ignore
reversed receipts, and adds `reverse_trip_repayment`. No direct client
UPDATE/DELETE grants are added.

**Compatibility:** All devices should upgrade to this app version.
Old APKs that read `trip_repayments` without filtering reversed records
could show incorrect local balances after a reversal, although the
server-side debt checks will use the updated active-receipts logic.

## Verification

    flutter pub get
    flutter gen-l10n
    flutter analyze
    flutter build apk --release

Test on 2 members:
- A owes B SGD 100, B confirms SGD 40 received.
- B reverses that receipt with a reason. A again owes the original
  amount, and the SGD 40 receipt appears as **Reversed** in history.
- A cannot reverse a receipt owed to B; a second reversal fails.
- B can subsequently confirm a correct amount.
- Test MYR receipts and exchange-rate conversions, and test after
  a full app restart.
- Check that older history still displays without crashes.

No Flutter or live SQL tests ran in the editing environment.
