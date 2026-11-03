# Original-currency trip expense totals

The **Who owes whom** page previously showed a single grand total converted
to the trip spending currency. This looked misleading when flights and hotels
were charged in SGD but in-trip purchases were charged in THB.

## New summary

For a group configured with **spending currency THB**, **settlement currency
SGD**, and **1 SGD = 25 THB**:

| Source of spending | Original amount | Approximate SGD equivalent |
|---|---:|---:|
| Flights and hotel, paid in SGD | SGD 2,000.00 | SGD 2,000.00 |
| Travel expenses, paid in THB | THB 6,000.00 | SGD 240.00 |
| **Combined trip expenses** | | **≈ SGD 2,240.00** |

It keeps a row for each *actual transaction currency*, sums the
original amount within that currency, and uses the group's registered
rate to convert THB (or the configured spending currency) to SGD (or
the configured settlement currency). Payments **originally in SGD stay
in SGD**; they are not first inflated into THB.

For extra currencies outside the configured spending/settlement pair,
the combined equivalent uses their **saved per-expense conversion to
spending currency**, then applies the group's registered conversion to
settlement currency. The UI marks these figures as approximations.

This change is **presentation/summary only**:
- The existing balance/settlement calculation remains in the group's
  spending currency with the recorded per-expense rates.
- Original amounts remain unchanged in Supabase.
- **Shared member-paid expenses** are summarized here; fund-paid
  purchases are accounted for separately in Common Fund. The UI
  discloses that exclusion.
- No new SQL migration is necessary; the prior currency columns from
  `20261103_000006_expense_currencies.sql` are reused.

## Validation

```bash
git checkout master
git pull origin master
flutter pub get
flutter gen-l10n
flutter analyze
flutter test test/expense_currency_summary_test.dart
flutter build apk --release
```

Check the SGD 2,000 + THB 6,000 example; test multiple transactions
of each currency, mixed third currencies, and an empty group.

Important: this combined total is an **estimate** based on the
trip-registered rate. If someone manually overrides an individual
expense rate, the total estimate may differ slightly from the debt
ledger derived from the expense's saved conversion. Always agree
the actual settlement amount before transferring money.
