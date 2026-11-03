/// Original-currency totals for shared (member-paid) expenses.
///
/// The existing settlement engine works in the group's spending currency.
/// This summary intentionally preserves the currency actually charged for
/// each expense, rather than converting every amount into the trip currency.
class ExpenseCurrencyTotal {
  const ExpenseCurrencyTotal(
    this.currency, this.cents, this.count, this.settlementCents);
  final String currency;
  final int cents;
  final int count;
  final int settlementCents;
}

class ExpenseCurrencySummary {
  const ExpenseCurrencySummary({
    required this.totals,
    required this.totalSettlementCurrency,
    required this.totalSettlementCents,
    required this.usesOtherCurrencyRates,
  });

  final List<ExpenseCurrencyTotal> totals;
  final String totalSettlementCurrency;
  final int totalSettlementCents;

  /// True if one or more expenses are outside the group's spending and
  /// settlement currencies; their previously saved per-expense rates apply.
  final bool usesOtherCurrencyRates;

  static int _cents(Object? value) {
    final s = value?.toString().trim() ?? '';
    final match = RegExp(r'^(\d+)(?:\.(\d{1,2}))?$').firstMatch(s);
    if (match == null) throw FormatException('Invalid monetary amount', s);
    return int.parse(match.group(1)!) * 100 +
        int.parse((match.group(2) ?? '').padRight(2, '0'));
  }

  static ExpenseCurrencySummary calculate({
    required List<Map<String, dynamic>> expenses,
    required String spendingCurrency,
    required String settlementCurrency,
    required double spendingPerSettlement,
  }) {
    if (!spendingPerSettlement.isFinite || spendingPerSettlement <= 0) {
      throw ArgumentError.value(
        spendingPerSettlement, 'spendingPerSettlement',
        'The trip exchange rate must be positive',
      );
    }

    final grouped = <String, int>{};
    final counts = <String, int>{};
    final settlementByCurrency = <String, double>{};
    var settlementTotal = 0.0;
    var hasOtherCurrencies = false;

    for (final expense in expenses) {
      final originalCurrency = expense['currency'] as String;
      final originalCents = _cents(expense['amount']);
      if (originalCents <= 0) {
        throw FormatException('Expense amount must be positive');
      }
      grouped.update(originalCurrency, (value) => value + originalCents,
          ifAbsent: () => originalCents);
      counts.update(originalCurrency, (value) => value + 1, ifAbsent: () => 1);

      double convertedCents;
      if (originalCurrency == settlementCurrency) {
        // A real SGD expense stays SGD; never convert it to THB and back.
        convertedCents = originalCents.toDouble();
      } else if (originalCurrency == spendingCurrency) {
        // THB charged is converted using the trip's registered exchange rate.
        convertedCents = originalCents / spendingPerSettlement;
      } else {
        // For additional currencies, keep the conversion saved with the
        // expense rather than assuming a rate to the settlement currency.
        hasOtherCurrencies = true;
        convertedCents =
            _cents(expense['amount_spending']) / spendingPerSettlement;
      }
      settlementTotal += convertedCents;
      settlementByCurrency.update(
        originalCurrency, (value) => value + convertedCents,
        ifAbsent: () => convertedCents,
      );
    }

    final totals = [
      for (final entry in grouped.entries)
        ExpenseCurrencyTotal(entry.key, entry.value, counts[entry.key]!,
            settlementByCurrency[entry.key]!.round()),
    ]..sort((a, b) {
        if (a.currency == settlementCurrency) return -1;
        if (b.currency == settlementCurrency) return 1;
        if (a.currency == spendingCurrency) return -1;
        if (b.currency == spendingCurrency) return 1;
        return a.currency.compareTo(b.currency);
      });

    return ExpenseCurrencySummary(
      totals: totals,
      totalSettlementCurrency: settlementCurrency,
      totalSettlementCents: settlementTotal.round(),
      usesOtherCurrencyRates: hasOtherCurrencies,
    );
  }
}
