# Settlement display currency and bottom navigation fix

- **Who owes whom** can display suggested repayments in either the group
  spending currency (e.g. JPY) or the configured settlement currency (e.g.
  SGD). The settlement currency is selected by default when different.
- The primary repayment amount and member balances use the chosen display;
  the suggested repayment also shows the other currency for reference.
- Conversions use the group's fixed manual rate; the `≈` sign and an
  explanatory note distinguish these estimates from confirmed payment values.
- Shared repayment requests follow the selected display currency and include
  the original amount plus a conversion disclaimer.
- The underlying balance calculation and repayment ledger **remain in the
  spending currency**. Changing the display is not a bank payment nor a new
  exchange-rate lookup.
- Added `SafeArea` bottom protection and extra scroll padding to the
  Who Owes Whom screen and repayment confirmation form. This prevents the
  explanatory text below **Member balances**, as well as the confirmation
  button, from being hidden behind Android system navigation.

Test on a phone with 3-button and gesture navigation. For a group with
JPY spending, SGD settlement and a rate of 115 JPY per SGD, a JPY 11,500
repayment should display approximately SGD 100.00 when SGD is selected.
Verify WhatsApp sharing respects the selection and that confirmed repayment
records still store JPY.

No Supabase migration is required. Run `flutter gen-l10n`,
`flutter analyze`, and an Android release build after merging.
