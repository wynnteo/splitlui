/// Pure cent-based fund arithmetic, independent of Flutter/Supabase.
class FundReconciliation {
  static int cents(num amount) => (amount.toDouble() * 100).round();

  static int sumEntries(List<Map<String, dynamic>> entries, String type) {
    return entries.where((row) => row['entry_type'] == type)
      .fold<int>(0, (total, row) => total + cents(row['amount'] as num));
  }

  static int sumRefunds(List<Map<String, dynamic>> refunds) =>
      refunds.fold<int>(0,
        (total, row) => total + cents(row['amount'] as num));

  static int contributionOutstanding({
    required int targetCents, required int contributedCents,
  }) => targetCents > contributedCents
      ? targetCents - contributedCents : 0;

  static bool reconciles({
    required int contributions,
    required int purchases,
    required int refunds,
    required int balance,
  }) => contributions - purchases - refunds == balance;
}
