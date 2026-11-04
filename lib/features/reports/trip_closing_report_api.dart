import 'package:supabase_flutter/supabase_flutter.dart';
import '../expenses/offline_expense_outbox.dart';
import 'trip_closing_snapshot.dart';

class TripClosingReportData {
  TripClosingReportData({
    required this.snapshot,required this.expenses,required this.repayments,
    required this.fundEntries,required this.fundRefunds,
    required this.receipts,required this.generatedAt,
  });
  final TripClosingSnapshot snapshot;
  final List<Map<String,dynamic>> expenses,repayments,fundEntries,fundRefunds;
  final List<Map<String,dynamic>> receipts;
  final DateTime generatedAt;
}

class TripClosingReportApi {
  TripClosingReportApi({SupabaseClient? client})
    : db=client ?? Supabase.instance.client;
  final SupabaseClient db;

  Future<List<Map<String,dynamic>>> _all(String table,String columns,
      String groupId) async {
    const batch=500;
    final rows=<Map<String,dynamic>>[];
    var start=0;
    while(true) {
      final response=await db.from(table).select(columns)
        .eq('group_id',groupId)
        .order('id',ascending:true).range(start,start+batch-1);
      final page=(response as List)
        .map((e)=>Map<String,dynamic>.from(e as Map)).toList();
      rows.addAll(page);
      if(page.length<batch)break;
      start+=batch;
    }
    return rows;
  }

  Future<TripClosingReportData> load({
    required String groupId,
    required List<String> memberIds,
    required String spendingCurrency,
    required String settlementCurrency,
    required double rate,
    required bool includeReceipts,
  }) async {
    if(db.auth.currentUser==null)throw StateError('Sign in first');
    // All financial queries must complete. Never create a partial
    // "final statement" when a required table or RLS read fails.
    final rows=await Future.wait<dynamic>([
      _all('trip_expenses',
        'id,title,amount,currency,amount_spending,paid_by,created_at',
        groupId),
      _all('trip_expense_shares','id,expense_id,user_id,share_spending',
        groupId),
      _all('trip_repayments',
        'id,from_user_id,to_user_id,amount_spending,paid_amount,paid_currency,note,created_at,reversed_at,reversal_reason',
        groupId),
      _all('trip_fund_entries',
        'id,entry_type,amount,member_id,description,created_at',
        groupId),
      _all('trip_fund_refunds',
        'id,member_id,amount,note,created_at',groupId),
      _all('trip_fund_targets',
        'group_id,member_id,target_amount',groupId),
      db.from('trip_fund_accounts').select('balance')
        .eq('group_id',groupId).maybeSingle(),
      if(includeReceipts)
        _all('trip_receipts',
          'id,expense_id,fund_entry_id,object_path',groupId),
    ]);
    final expenses=rows[0] as List<Map<String,dynamic>>;
    final shares=rows[1] as List<Map<String,dynamic>>;
    final repayments=rows[2] as List<Map<String,dynamic>>;
    final fundEntries=rows[3] as List<Map<String,dynamic>>;
    final refunds=rows[4] as List<Map<String,dynamic>>;
    final targets=rows[5] as List<Map<String,dynamic>>;
    final account=rows[6] as Map<String,dynamic>?;
    final pending=await OfflineExpenseOutbox.instance.pending(groupId);
    if(account==null && fundEntries.isNotEmpty) {
      throw StateError('Fund entries exist but fund account is missing');
    }
    return TripClosingReportData(
      snapshot:TripClosingSnapshot.calculate(
        memberIds:memberIds,spendingCurrency:spendingCurrency,
        settlementCurrency:settlementCurrency,
        spendingPerSettlement:rate,
        expenses:expenses,shares:shares,repayments:repayments,
        fundEntries:fundEntries,fundRefunds:refunds,fundTargets:targets,
        fundBalanceCents:account==null ? 0 :
          (account['balance'] as num).toDouble().multiplyCents(),
        pendingLocalCount:pending.length),
      expenses:expenses,repayments:repayments,
      fundEntries:fundEntries,fundRefunds:refunds,
      receipts:includeReceipts ? rows[7] as List<Map<String,dynamic>> : [],
      generatedAt:DateTime.now(),
    );
  }
}

extension _Cents on double {
  int multiplyCents() => (this*100).round();
}
