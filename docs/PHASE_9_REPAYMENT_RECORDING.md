# Phase 9 — Manually confirm repayments

## What this feature does
On **Groups → [group] → Who owes whom**, each suggested transfer
has a **Confirm money received** action **only for the recipient**.
After money has actually arrived (cash, PayNow, bank transfer etc.),
the recipient records the amount, in the group's **spending currency**.
The receipt is stored in Supabase and all members see it.

After saving, the preview recalculates outstanding debts and
suggested transfers. Full and partial repayments are supported.

### Example
Alice pays JPY 10,000 dinner split 50/50 with Bob.
Bob owes Alice JPY 5,000. Bob sends JPY 2,000, and Alice confirms
the receipt. SplitLui now shows **Bob → Alice JPY 3,000** remaining.
If Alice confirms another JPY 3,000, the suggestion disappears.

If the group spending currency is JPY and Bob actually transfers
SGD using PayNow, agree how much JPY that represents **before**
recording the receipt. The app currently records repayment amounts
in the group's spending currency only, not the original bank
transaction currency. The SGD figure shown as an estimate on the
settlement screen is *not a verified banking rate*.

## Permissions and integrity
- **Only the intended recipient** may confirm their own receipt
  (the database enforces this, not just the app).
- Two different current group members are required.
- A repayment can never exceed either the debtor's current
  outstanding negative balance or the recipient's positive balance.
- Server locks the group row to prevent two simultaneous repayments
  from overpaying.
- All group members can **read** receipts; direct table writes are
  denied by RLS/grants. Only the authenticated RPC can insert.
- Receipt entry is **manual confirmation**, not proof that a bank
  transfer occurred. No funds are sent by this app.
- Common Fund transactions remain separate.
- This first release has no correction/reversal of an incorrectly
  confirmed repayment. Do NOT confirm a payment before receiving it.

## Setup
Merge PR, then run in your **Supabase SQL Editor**:

    supabase/migrations/20261103_000007_trip_repayments.sql

Requires previous group, expense and per-expense currency migrations.
GitHub merges do not automatically modify the database.

In Android Studio:

    git checkout master
    git pull origin master
    flutter pub get
    flutter gen-l10n
    flutter analyze
    flutter test test/settlement_calculator_test.dart

Run normally, open a group and select **Who owes whom**.

## Test using two devices
1. Alice's account creates a group and invites Bob.
2. Alice pays a JPY 10,000 expense split equally.
3. Bob opens settlement preview; Bob should see payment instructions
   but **cannot** claim Alice received it.
4. Alice opens settlement preview; Alice can confirm JPY 2,000 received.
5. Verify both devices refresh and show Bob still owes JPY 3,000.
6. Alice confirms another JPY 3,000 and open debt becomes zero.
7. Confirm duplicate or excessive amount RPC returns an error and
   does **not** create an additional receipt.
8. Test EN/Chinese, two currencies, smaller phones and dark mode.

## Known limitations
- No bank verification, QR generation, WhatsApp share or PayNow integration.
- No general refund, paid history corrections or disputes yet.
- No payment initiation or payment-reminder notifications.
- Group's spending currency is the repayment ledger currency; conversion
  to settlement currency is still approximate and current-rate based.
- The repayment history is retained; there is no undo in this phase.
- Existing guest accounts are device-bound, and may lose access if
  app data is cleared or the app is uninstalled.

**Validation:** Flutter analyzer/tests and live Supabase migration have
not been executed in this repository-editing environment. Verify on a
test group before entering actual payments.
