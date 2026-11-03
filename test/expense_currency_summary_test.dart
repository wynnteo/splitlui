import 'package:flutter_test/flutter_test.dart';
import 'package:splitlui/features/settlement/expense_currency_summary.dart';

void main() {
  Map<String, dynamic> expense(String currency, String amount,
      String spendingAmount) => {
    'currency': currency,
    'amount': amount,
    'amount_spending': spendingAmount,
  };

  test('SGD flight remains SGD; THB travel expense stays THB', () {
    final summary = ExpenseCurrencySummary.calculate(
      spendingCurrency: 'THB',
      settlementCurrency: 'SGD',
      spendingPerSettlement: 25,
      expenses: [
        expense('SGD', '2000.00', '50000.00'),
        expense('THB', '6000.00', '6000.00'),
      ],
    );
    expect(summary.totals.map((x) => x.currency), ['SGD', 'THB']);
    expect(summary.totals.map((x) => x.cents), [200000, 600000]);
    expect(summary.totalSettlementCurrency, 'SGD');
    expect(summary.totalSettlementCents, 224000);
    expect(summary.usesOtherCurrencyRates, false);
  });

  test('Multiple expenses in same original currency are combined', () {
    final summary = ExpenseCurrencySummary.calculate(
      spendingCurrency: 'THB',
      settlementCurrency: 'SGD',
      spendingPerSettlement: 25,
      expenses: [
        expense('SGD', '1234.56', '30864.00'),
        expense('SGD', '100.44', '2511.00'),
        expense('THB', '500.00', '500.00'),
      ],
    );
    expect(summary.totals[0].cents, 133500);
    expect(summary.totals[0].count, 2);
    expect(summary.totals[1].count, 1);
    expect(summary.totalSettlementCents, 135500);
  });

  test('Third currency uses the saved spending conversion', () {
    final summary = ExpenseCurrencySummary.calculate(
      spendingCurrency: 'THB',
      settlementCurrency: 'SGD',
      spendingPerSettlement: 25,
      expenses: [
        expense('USD', '50.00', '1700.00'),
      ],
    );
    expect(summary.totals.single.currency, 'USD');
    expect(summary.totalSettlementCents, 6800);
    expect(summary.usesOtherCurrencyRates, true);
  });

  test('Empty expenses show zero and no currency rows', () {
    final summary = ExpenseCurrencySummary.calculate(
      spendingCurrency: 'THB',
      settlementCurrency: 'SGD',
      spendingPerSettlement: 25,
      expenses: [],
    );
    expect(summary.totals, isEmpty);
    expect(summary.totalSettlementCents, 0);
  });

  test('Invalid exchange rate is rejected', () {
    expect(() => ExpenseCurrencySummary.calculate(
      spendingCurrency: 'THB',
      settlementCurrency: 'SGD',
      spendingPerSettlement: 0,
      expenses: [],
    ), throwsArgumentError);
  });
}
