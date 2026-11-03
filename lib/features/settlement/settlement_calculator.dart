/// Integer-cent settlement calculations, independent of Flutter/Supabase.
///
/// All balances are expressed in the group's spending currency, because the
/// server already persists each expense and share's fixed conversion.
/// An expense credited to its payer must never be counted as a fund payment.
class MemberBalance {
  const MemberBalance(this.userId, this.cents);
  final String userId;
  final int cents; // Positive = owed money; negative = owes money.
}

class SuggestedTransfer {
  const SuggestedTransfer(this.fromUserId, this.toUserId, this.cents);
  final String fromUserId, toUserId;
  final int cents;
}

class SettlementResult {
  const SettlementResult({
    required this.balances,
    required this.transfers,
    required this.totalExpenseCents,
  });

  final List<MemberBalance> balances;
  final List<SuggestedTransfer> transfers;
  final int totalExpenseCents;
}

class SettlementCalculator {
  /// Supabase numeric(18,2) may be decoded as num or as decimal text.
  /// Convert safely into integer cents for stable exact allocation arithmetic.
  static int cents(Object? amount) {
    final value = amount?.toString().trim() ?? '';
    final match = RegExp(r'^(-?)(\d+)(?:\.(\d{1,2}))?$').firstMatch(value);
    if (match == null) {
      throw FormatException('Invalid 2-decimal currency amount', value);
    }
    final units = int.parse(match.group(2)!);
    final fraction = (match.group(3) ?? '').padRight(2, '0');
    return (match.group(1) == '-' ? -1 : 1) *
        (units * 100 + int.parse(fraction.isEmpty ? '0' : fraction));
  }

  static SettlementResult calculate({
    required List<String> memberIds,
    required List<Map<String, dynamic>> expenses,
    required List<Map<String, dynamic>> shares,
    List<Map<String, dynamic>> repayments = const [],
  }) {
    final balance = <String, int>{for (final id in memberIds) id: 0};
    final expensesById = <String, Map<String, dynamic>>{};
    var total = 0;

    for (final expense in expenses) {
      final id = expense['id'] as String;
      final payer = expense['paid_by'] as String;
      if (!balance.containsKey(payer)) {
        throw StateError('Payer no longer belongs to this group');
      }
      final amount = cents(expense['amount_spending']);
      if (amount <= 0 || expensesById.containsKey(id)) {
        throw StateError('Invalid or duplicated expense');
      }
      balance[payer] = balance[payer]! + amount;
      total += amount;
      expensesById[id] = expense;
    }

    final shareTotals = <String, int>{};
    final allocated = <String>{};
    for (final share in shares) {
      final expenseId = share['expense_id'] as String;
      final userId = share['user_id'] as String;
      if (!expensesById.containsKey(expenseId) ||
          !balance.containsKey(userId)) {
        throw StateError('Expense share references unknown member or expense');
      }
      final key = '$expenseId/$userId';
      if (!allocated.add(key)) throw StateError('Duplicate expense share');
      final amount = cents(share['share_spending']);
      if (amount < 0) throw StateError('Negative expense share');
      balance[userId] = balance[userId]! - amount;
      shareTotals[expenseId] = (shareTotals[expenseId] ?? 0) + amount;
    }
    for (final entry in expensesById.entries) {
      if (shareTotals[entry.key] != cents(entry.value['amount_spending'])) {
        throw StateError('Expense shares do not match converted expense');
      }
    }

    final seenPayments = <String>{};
    for (final repayment in repayments) {
      final id = repayment['id'] as String;
      final from = repayment['from_user_id'] as String;
      final to = repayment['to_user_id'] as String;
      if (!seenPayments.add(id) || from == to ||
          !balance.containsKey(from) || !balance.containsKey(to)) {
        throw StateError('Invalid repayment record');
      }
      final value = cents(repayment['amount_spending']);
      if (value <= 0) throw StateError('Invalid repayment amount');
      balance[from] = balance[from]! + value;
      balance[to] = balance[to]! - value;
    }

    final positives = balance.entries.where((e) => e.value > 0)
        .map((e) => MemberBalance(e.key, e.value)).toList()
      ..sort((a, b) {
        final diff = b.cents.compareTo(a.cents);
        return diff != 0 ? diff : a.userId.compareTo(b.userId);
      });
    final negatives = balance.entries.where((e) => e.value < 0)
        .map((e) => MemberBalance(e.key, -e.value)).toList()
      ..sort((a, b) {
        final diff = b.cents.compareTo(a.cents);
        return diff != 0 ? diff : a.userId.compareTo(b.userId);
      });
    final credit = [for (final p in positives) p.cents];
    final debt = [for (final n in negatives) n.cents];
    final transfers = <SuggestedTransfer>[];
    var i = 0;
    var j = 0;
    while (i < negatives.length && j < positives.length) {
      final amount = debt[i] < credit[j] ? debt[i] : credit[j];
      if (amount <= 0) throw StateError('Invalid settlement allocation');
      transfers.add(SuggestedTransfer(
          negatives[i].userId, positives[j].userId, amount));
      debt[i] -= amount;
      credit[j] -= amount;
      if (debt[i] == 0) i++;
      if (credit[j] == 0) j++;
    }
    if (i != negatives.length || j != positives.length ||
        balance.values.fold<int>(0, (sum, n) => sum + n) != 0) {
      throw StateError('Settlement balance does not reconcile');
    }

    return SettlementResult(
      balances: [
        for (final entry in balance.entries)
          MemberBalance(entry.key, entry.value),
      ],
      transfers: transfers,
      totalExpenseCents: total,
    );
  }
}
