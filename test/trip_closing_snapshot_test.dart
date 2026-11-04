import 'package:flutter_test/flutter_test.dart';
import 'package:splitlui/features/reports/trip_closing_snapshot.dart';

void main() {
  final members=['alex','ben'];
  final expenses=<Map<String,dynamic>>[
    {'id':'e1','paid_by':'alex','amount':100.0,
      'currency':'SGD','amount_spending':2500.0},
    {'id':'e2','paid_by':'ben','amount':1000.0,
      'currency':'THB','amount_spending':1000.0},
  ];
  final shares=<Map<String,dynamic>>[
    {'expense_id':'e1','user_id':'alex','share_spending':1250.0},
    {'expense_id':'e1','user_id':'ben','share_spending':1250.0},
    {'expense_id':'e2','user_id':'alex','share_spending':500.0},
    {'expense_id':'e2','user_id':'ben','share_spending':500.0},
  ];
  TripClosingSnapshot make({
    List<Map<String,dynamic>> repayments=const [],
    List<Map<String,dynamic>> fundEntries=const [],
    List<Map<String,dynamic>> refunds=const [],
    List<Map<String,dynamic>> targets=const [],
    int balance=0,int pending=0,
  })=>TripClosingSnapshot.calculate(
    memberIds:members,spendingCurrency:'THB',
    settlementCurrency:'SGD',spendingPerSettlement:25,
    expenses:expenses,shares:shares,repayments:repayments,
    fundEntries:fundEntries,fundRefunds:refunds,fundTargets:targets,
    fundBalanceCents:balance,pendingLocalCount:pending);

  test('Keeps original SGD/THB totals and excludes Common Fund purchases',(){
    final snap=make(fundEntries:[
      {'entry_type':'contribution','amount':300.0,'member_id':'alex'},
      {'entry_type':'expense','amount':100.0,'member_id':null},
    ],balance:20000);
    expect(snap.expenseSummary.totals.length,2);
    expect(snap.expenseSummary.totalSettlementCents,14000);
    expect(snap.settlements.totalExpenseCents,350000);
    expect(snap.fundSpentCents,10000);
    expect(snap.fundReconciles,isTrue);
  });

  test('Reversed repayments never reduce balances',(){
    final receipt=<String,dynamic>{
      'id':'r1','from_user_id':'ben','to_user_id':'alex',
      'amount_spending':750.0,'reversed_at':null,
    };
    final active=make(repayments:[receipt]);
    final reversed=make(repayments:[
      {...receipt,'reversed_at':'2026-11-04T00:00:00Z'}
    ]);
    expect(active.activeRepayments,1);
    expect(reversed.activeRepayments,0);
    expect(reversed.reversedRepayments,1);
    expect(active.settlements.transfers.first.cents,
      lessThan(reversed.settlements.transfers.first.cents));
  });

  test('Fund targets, refunds and unsynced entries keep report non-final',(){
    final snap=make(fundEntries:[
      {'entry_type':'contribution','amount':200.0,'member_id':'alex'},
      {'entry_type':'expense','amount':50.0,'member_id':null},
    ],refunds:[{'amount':25.0,'member_id':'alex'}],
    targets:[{'member_id':'alex','target_amount':250.0}],
    balance:12500,pending:1);
    expect(snap.fundReconciles,isTrue);
    expect(snap.fundOutstandingCents,5000);
    expect(snap.fundRefundsCents,2500);
    expect(snap.pendingLocalCount,1);
    expect(snap.needsReview,isTrue);
  });

  test('Mismatched fund balance is always flagged',(){
    expect(make(balance:100).fundReconciles,isFalse);
  });
}
