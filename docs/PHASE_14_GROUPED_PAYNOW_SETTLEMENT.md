# Grouped PayNow settlement display

On **Who owes whom**, suggested repayments are grouped by the person who
needs to receive money, rather than displaying a separate disconnected card
for every transfer.

Each recipient section shows:
- Recipient name, total incoming amount (in the chosen display currency)
- Their saved per-group PayNow mobile number **once**, with copy action,
  visible to all group members
- Each person who needs to pay them, with the individual amount
- **Share payment request** and **Confirm received** actions only for the
  authenticated recipient, per transfer

If the recipient has not supplied a PayNow mobile, the section instead
prompts members to ask them for payment details. Members can update their
own number from **My PayNow details** at the top.

## Netting matters

Example original obligations may be A/B/C → D, B/C → A and D/C → B.
The app's existing settlement calculator first nets expenses and repayments
across the group and proposes a smaller set of transfers. The UI groups
those **suggested net transfers** by recipient; it does not imply that every
original expense-level pair is a separate outstanding payment.

## Tests

After merging:

```sh
flutter pub get
flutter gen-l10n
flutter analyze
flutter build apk --release
```

On two or more group member devices:
1. Give several members different PayNow numbers.
2. Add expenses with different payers and selected participants; ensure
   more than one recipient has an outstanding net credit.
3. Open **Who owes whom**; confirm each recipient appears once and the
   corresponding payers and amounts appear under the correct recipient.
4. Copy a recipient's PayNow mobile as another group member.
5. Verify only the recipient can share their request or confirm money
   received. Record a partial repayment and refresh; totals must update.
6. Switch the display between group spending and settlement currencies
   (e.g. JPY / SGD). Confirm conversion is labeled approximate.
7. Verify narrow-screen layout and Android navigation safe-area spacing.

No new Supabase SQL migration or changed settlement algorithm is required.
The assistant did source structural checks, not a Flutter compile or device run.
