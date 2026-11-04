import '../settlement/expense_currency_summary.dart';
import '../settlement/settlement_calculator.dart';
import '../fund/fund_reconciliation.dart';

/// A read-only snapshot; never changes ledger state or marks a trip closed.
class TripClosingSnapshot {
  TripClosingSnapshot({
    required this.expenseSummary,
    required this.settlements,
    required this.fundContributionsCents,
    required this.fundSpentCents,
    required this.fundRefundsCents,
    required this.fundBalanceCents,
    required this.fundTargetCents,
    required this.fundOutstandingCents,
    required this.activeRepayments,
    required this.reversedRepayments,
    required this.pendingLocalCount,
  });

  final ExpenseCurrencySummary expenseSummary;
  final SettlementResult settlements;
  final int fundContributionsCents, fundSpentCents, fundRefundsCents;
  final int fundBalanceCents, fundTargetCents, fundOutstandingCents;
  final int activeRepayments, reversedRepayments, pendingLocalCount;

  bool get fundReconciles => FundReconciliation.reconciles(
    contributions:fundContributionsCents,
    purchases:fundSpentCents,
    refunds:fundRefundsCents,
    balance:fundBalanceCents,
  );
  bool get hasOutstandingDebts => settlements.transfers.isNotEmpty;
  bool get needsReview => !fundReconciles || hasOutstandingDebts ||
    fundOutstandingCents>0 || pendingLocalCount>0;

  static TripClosingSnapshot calculate({
    required List<String> memberIds,
    required String spendingCurrency,
    required String settlementCurrency,
    required double spendingPerSettlement,
    required List<Map<String,dynamic>> expenses,
    required List<Map<String,dynamic>> shares,
    required List<Map<String,dynamic>> repayments,
    required List<Map<String,dynamic>> fundEntries,
    required List<Map<String,dynamic>> fundRefunds,
    required List<Map<String,dynamic>> fundTargets,
    required int fundBalanceCents,
    required int pendingLocalCount,
  }) {
    final active=repayments.where((r)=>r['reversed_at']==null).toList();
    final balances=SettlementCalculator.calculate(
      memberIds:memberIds,expenses:expenses,shares:shares,repayments:active);
    final summary=ExpenseCurrencySummary.calculate(
      expenses:expenses,spendingCurrency:spendingCurrency,
      settlementCurrency:settlementCurrency,
      spendingPerSettlement:spendingPerSettlement);

    final targetByMember=<String,int>{};
    final collectedByMember=<String,int>{};
    for(final row in fundTargets) {
      targetByMember[row['member_id'] as String] =
        SettlementCalculator.cents(row['target_amount']);
    }
    for(final row in fundEntries) {
      if(row['entry_type']!='contribution')continue;
      final member=row['member_id'] as String?;
      if(member==null)continue;
      collectedByMember[member]=(collectedByMember[member]??0)+
        SettlementCalculator.cents(row['amount']);
    }
    var outstanding=0;
    for(final member in memberIds) {
      outstanding+=FundReconciliation.contributionOutstanding(
        targetCents:targetByMember[member]??0,
        contributedCents:collectedByMember[member]??0);
    }
    return TripClosingSnapshot(
      expenseSummary:summary,settlements:balances,
      fundContributionsCents:FundReconciliation.sumEntries(fundEntries,'contribution'),
      fundSpentCents:FundReconciliation.sumEntries(fundEntries,'expense'),
      fundRefundsCents:FundReconciliation.sumRefunds(fundRefunds),
      fundBalanceCents:fundBalanceCents,
      fundTargetCents:targetByMember.values.fold(0,(a,b)=>a+b),
      fundOutstandingCents:outstanding,
      activeRepayments:active.length,
      reversedRepayments:repayments.length-active.length,
      pendingLocalCount:pendingLocalCount,
    );
  }
}
