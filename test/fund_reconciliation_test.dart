import 'package:flutter_test/flutter_test.dart';
import 'package:splitlui/features/fund/fund_reconciliation.dart';

void main() {
  test('Counts confirmed contributions, expenses, refunds once', () {
    final ledger = <Map<String,dynamic>>[
      {'entry_type':'contribution','amount':200.00},
      {'entry_type':'contribution','amount':150.00},
      {'entry_type':'expense','amount':125.50},
    ];
    final refunds = <Map<String,dynamic>>[{'amount':24.50}];
    final collected=FundReconciliation.sumEntries(ledger,'contribution');
    final spent=FundReconciliation.sumEntries(ledger,'expense');
    final returned=FundReconciliation.sumRefunds(refunds);
    expect(collected,35000);
    expect(spent,12550);
    expect(returned,2450);
    expect(FundReconciliation.reconciles(
      contributions:collected,purchases:spent,
      refunds:returned,balance:20000),isTrue);
  });

  test('Promised target is not counted as cash', () {
    expect(FundReconciliation.contributionOutstanding(
      targetCents:20000,contributedCents:5000),15000);
    expect(FundReconciliation.contributionOutstanding(
      targetCents:10000,contributedCents:12000),0);
  });

  test('Mismatched fund balance is surfaced', () {
    expect(FundReconciliation.reconciles(
      contributions:50000,purchases:10000,refunds:5000,
      balance:30000),isFalse);
  });
}
