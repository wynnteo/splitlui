import 'package:flutter_test/flutter_test.dart';
import 'package:splitlui/features/settlement/settlement_calculator.dart';

void main() {
  test('rounding: 100.01 split 3 ways exactly in cents', () {
    final data = SettlementCalculator.calculate(
      memberIds: ['alice', 'bob', 'charlie'],
      expenses: [
        {'id': 'dinner', 'paid_by': 'alice', 'amount_spending': 100.01},
      ],
      shares: [
        {'expense_id': 'dinner', 'user_id': 'alice',
          'share_spending': 33.34},
        {'expense_id': 'dinner', 'user_id': 'bob',
          'share_spending': 33.34},
        {'expense_id': 'dinner', 'user_id': 'charlie',
          'share_spending': 33.33},
      ],
    );
    expect(data.totalExpenseCents, 10001);
    final balances = {for (final b in data.balances) b.userId: b.cents};
    expect(balances, {'alice': 6667, 'bob': -3334, 'charlie': -3333});
    expect(data.transfers.length, 2);
    expect(data.transfers.map((t) => t.cents).toList(), [3334, 3333]);
    expect(data.transfers.every((t) => t.toUserId == 'alice'), isTrue);
  });

  test('mixed-currency expenses use stored JPY amounts, not raw SGD', () {
    // Flight: SGD 300 = JPY 34,500; restaurant: JPY 9,000.
    final data = SettlementCalculator.calculate(
      memberIds: ['alice', 'bob'],
      expenses: [
        {'id': 'flight', 'paid_by': 'alice', 'amount_spending': 34500.00},
        {'id': 'meal', 'paid_by': 'bob', 'amount_spending': 9000.00},
      ],
      shares: [
        {'expense_id': 'flight', 'user_id': 'alice',
          'share_spending': 17250.00},
        {'expense_id': 'flight', 'user_id': 'bob',
          'share_spending': 17250.00},
        {'expense_id': 'meal', 'user_id': 'alice',
          'share_spending': 4500.00},
        {'expense_id': 'meal', 'user_id': 'bob',
          'share_spending': 4500.00},
      ],
    );
    expect(data.totalExpenseCents, 4350000);
    expect(data.transfers.length, 1);
    expect(data.transfers.single.fromUserId, 'bob');
    expect(data.transfers.single.toUserId, 'alice');
    expect(data.transfers.single.cents, 1275000); // JPY 12,750
  });

  test('no expenses means nobody owes anything', () {
    final data = SettlementCalculator.calculate(
      memberIds: ['alice', 'bob'],
      expenses: [],
      shares: [],
    );
    expect(data.totalExpenseCents, 0);
    expect(data.transfers, isEmpty);
    expect(data.balances.every((b) => b.cents == 0), isTrue);
  });

  test('refuses to give misleading results if shares are incomplete', () {
    expect(() => SettlementCalculator.calculate(
      memberIds: ['alice', 'bob'],
      expenses: [
        {'id': 'dinner', 'paid_by': 'alice', 'amount_spending': 50.00},
      ],
      shares: [
        {'expense_id': 'dinner', 'user_id': 'alice',
          'share_spending': 25.00},
      ],
    ), throwsStateError);
  });

  test('confirmed partial and full repayments update outstanding balances', () {
    final expenses = [
      {'id': 'dinner', 'paid_by': 'alice', 'amount_spending': 100.00},
    ];
    final shares = [
      {'expense_id': 'dinner', 'user_id': 'alice', 'share_spending': 50.00},
      {'expense_id': 'dinner', 'user_id': 'bob', 'share_spending': 50.00},
    ];
    final partial = SettlementCalculator.calculate(
      memberIds: ['alice', 'bob'], expenses: expenses, shares: shares,
      repayments: [
        {'id':'p1','from_user_id':'bob','to_user_id':'alice',
         'amount_spending':20.00},
      ],
    );
    expect(partial.transfers.single.cents, 3000);
    expect(partial.transfers.single.fromUserId, 'bob');
    expect(partial.transfers.single.toUserId, 'alice');

    final paid = SettlementCalculator.calculate(
      memberIds: ['alice', 'bob'], expenses: expenses, shares: shares,
      repayments: [
        {'id':'p1','from_user_id':'bob','to_user_id':'alice',
         'amount_spending':20.00},
        {'id':'p2','from_user_id':'bob','to_user_id':'alice',
         'amount_spending':30.00},
      ],
    );
    expect(paid.transfers, isEmpty);
    expect(paid.balances.every((b) => b.cents == 0), isTrue);
    expect(paid.totalExpenseCents, 10000);
  });

  test('rejects duplicate receipt IDs', () {
    expect(() => SettlementCalculator.calculate(
      memberIds: ['alice','bob'],
      expenses: [
        {'id':'e','paid_by':'alice','amount_spending':20.00}
      ],
      shares: [
        {'expense_id':'e','user_id':'alice','share_spending':10.00},
        {'expense_id':'e','user_id':'bob','share_spending':10.00},
      ],
      repayments: [
        {'id':'duplicate','from_user_id':'bob','to_user_id':'alice',
         'amount_spending':1.00},
        {'id':'duplicate','from_user_id':'bob','to_user_id':'alice',
         'amount_spending':1.00},
      ],
    ), throwsStateError);
  });

  test('decimal text conversion uses exact cents', () {
    expect(SettlementCalculator.cents('115.05'), 11505);
    expect(SettlementCalculator.cents('0.01'), 1);
    expect(SettlementCalculator.cents(-7.20), -720);
  });
}
