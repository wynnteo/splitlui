import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../ui/lui_style.dart';
import 'receipt_capture.dart';
import 'offline_expense_outbox.dart';
import 'fund_purchase_edit_page.dart';

class SharedExpenseApi {
  final SupabaseClient db = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> list(String groupId) async {
    final rows = await db.from('trip_expenses')
        .select('id,title,amount,currency,rate_to_spending,amount_spending,paid_by,created_by,created_at,updated_at,receipt_date')
        .eq('group_id', groupId).order('created_at', ascending: false);
    return (rows as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<Map<String,dynamic>?> fundBalance(String groupId) async {
    return await db.from('trip_fund_accounts')
        .select('balance').eq('group_id', groupId).maybeSingle();
  }

  Future<List<Map<String,dynamic>>> fundPurchases(String groupId) async {
    final rows = await db.from('trip_fund_entries')
        .select('id,description,amount,original_amount,original_currency,rate_to_spending,recorded_by,receipt_date,created_at,updated_at')
        .eq('group_id', groupId).eq('entry_type','expense')
        .order('created_at',ascending:false);
    return rows.map((r) => Map<String,dynamic>.from(r)).toList();
  }

  Future<String> addFundPurchase({
    required String groupId, required String title,
    required double amount, required String currency,
    required double rateToSpending,
  }) async {
    final id = await db.rpc('record_trip_fund_purchase',params: {
      'p_group':groupId, 'p_title':title.trim(), 'p_amount':amount,
      'p_currency':currency, 'p_rate_to_spending':rateToSpending,
    });
    return id.toString();
  }

  Future<String> add({
    required String groupId, required String title,
    required double amount, required String currency,
    required double rateToSpending, required String paidBy,
    required List<String> splitBetween,
  }) async {
    final id = await db.rpc('add_trip_expense_v2', params: {
      'p_group': groupId, 'p_title': title.trim(), 'p_amount': amount,
      'p_currency': currency, 'p_rate_to_spending': rateToSpending,
      'p_paid_by': paidBy, 'p_split_between': splitBetween,
    });
    return id.toString();
  }

  Future<void> saveReceiptDate({
    required String groupId, String? expenseId,
    String? fundEntryId, required DateTime? date,
  }) async {
    await db.rpc('set_trip_receipt_date', params: {
      'p_group': groupId, 'p_expense': expenseId,
      'p_fund_entry': fundEntryId,
      'p_date': date == null ? null :
        '${date.year.toString().padLeft(4,'0')}-'
        '${date.month.toString().padLeft(2,'0')}-'
        '${date.day.toString().padLeft(2,'0')}',
    });
  }

  Future<void> edit({
    required String groupId, required Map<String,dynamic> original,
    required String title, required double amount,
    required String currency, required double rateToSpending,
    required String paidBy, required List<String> participants,
    DateTime? receiptDate,
  }) async {
    await db.rpc('edit_trip_expense',params: {
      'p_group': groupId, 'p_expense': original['id'],
      'p_expected_updated_at': original['updated_at'],
      'p_title': title.trim(), 'p_amount': amount,
      'p_currency':currency, 'p_rate_to_spending':rateToSpending,
      'p_paid_by':paidBy,'p_split_between':participants,
      'p_date': receiptDate == null ? null :
          '${receiptDate.year.toString().padLeft(4,'0')}-'
          '${receiptDate.month.toString().padLeft(2,'0')}-'
          '${receiptDate.day.toString().padLeft(2,'0')}',
    });
  }

  Future<void> correctFundPurchase({
    required String groupId, required Map<String,dynamic> entry,
  }) async {
    await db.rpc('correct_trip_fund_purchase',params:{
      'p_group':groupId,'p_entry':entry['id'],
      'p_expected_updated_at':entry['updated_at'],
      'p_delete':true,'p_title':null,'p_amount':null,'p_currency':null,
      'p_rate_to_spending':null,'p_date':null,
    });
  }

  Future<void> delete({
    required String groupId, required Map<String,dynamic> original,
  }) async {
    await db.rpc('delete_trip_expense',params: {
      'p_group': groupId, 'p_expense': original['id'],
      'p_expected_updated_at': original['updated_at'],
    });
  }

  Future<List<Map<String, dynamic>>> shares(String expenseId) async {
    final rows = await db.from('trip_expense_shares')
        .select('user_id,share_amount,share_spending').eq('expense_id', expenseId);
    return (rows as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }
}

class SharedExpensesPage extends StatefulWidget {
  const SharedExpensesPage({
    super.key, required this.groupId, required this.groupName,
    required this.currency, required this.members,
    required this.groupRate, required this.settlementCurrency,
  });
  final String groupId, groupName, currency;
  final double groupRate;
  final String settlementCurrency;
  final List<Map<String, dynamic>> members;

  @override State<SharedExpensesPage> createState() => _SharedExpensesPageState();
}

class _SharedExpensesPageState extends State<SharedExpensesPage> with WidgetsBindingObserver {
  final api = SharedExpenseApi();
  List<Map<String, dynamic>> expenses = [];
  List<Map<String,dynamic>> fundPurchases = [];
  List<Map<String,Object?>> queuedExpenses = [];
  bool showingOfflineSnapshot = false;
  bool _refreshing = false;
  StreamSubscription<List<ConnectivityResult>>? _networkSubscription;
  bool busy = true;
  String? error;

  @override void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _networkSubscription = Connectivity().onConnectivityChanged.listen((states) {
      if (states.any((state) => state != ConnectivityResult.none) && mounted) {
        refresh();
      }
    });
    refresh();
  }

  @override void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _networkSubscription?.cancel();
    super.dispose();
  }

  @override void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !busy) refresh();
  }

  String memberName(String? id) {
    for (final m in widget.members) {
      if (m['user_id'] == id) return m['nickname'] as String? ?? '';
    }
    return id ?? '';
  }

  Future<void> refresh() async {
    if (_refreshing) return;
    _refreshing = true;
    if (mounted) setState(() { busy = true; error = null; });
    try {
      // Pending entries always come from device storage first so they remain
      // visible even when connectivity is unavailable.
      final storage = OfflineExpenseOutbox.instance;
      final before = await storage.pending(widget.groupId);
      final cached = await storage.cachedExpenses(widget.groupId);
      if (mounted) setState(() {
        queuedExpenses = before;
        if (cached.isNotEmpty) {
          expenses = cached;
          showingOfflineSnapshot = true;
        }
      });
      await OfflineExpenseOutbox.instance.sync(widget.groupId);
      final after = await OfflineExpenseOutbox.instance.pending(widget.groupId);
      if (mounted) setState(() => queuedExpenses = after);
      final result = await Future.wait([
        api.list(widget.groupId),
        api.fundPurchases(widget.groupId),
      ]);
      await storage.cacheExpenses(widget.groupId, result[0]);
      if (mounted) setState(() {
        expenses = result[0];
        fundPurchases = result[1];
        showingOfflineSnapshot = false;
      });
    } catch (e) {
      if (mounted) {
        // Do not erase the last local or online data on network failure.
        setState(() {
          error = e.toString();
          if (expenses.isNotEmpty) showingOfflineSnapshot = true;
        });
      }
    } finally {
      _refreshing = false;
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> createExpense() async {
    final added = await Navigator.push<bool>(context, MaterialPageRoute(
      builder: (_) => AddSharedExpensePage(
        api: api, groupId: widget.groupId,
        currency: widget.currency, members: widget.members,
        groupRate: widget.groupRate,
        settlementCurrency: widget.settlementCurrency),
    ));
    if (mounted && added == true) await refresh();
  }

  Future<void> editExpense(Map<String,dynamic> expense) async {
    final changed = await Navigator.push<bool>(context,MaterialPageRoute(
      builder: (_) => AddSharedExpensePage(
        api:api, groupId:widget.groupId, currency:widget.currency,
        settlementCurrency:widget.settlementCurrency,
        groupRate:widget.groupRate, members:widget.members,
        initialExpense:expense,
      ),
    ));
    if (mounted && changed == true) await refresh();
  }

  Future<void> deleteExpense(Map<String,dynamic> expense) async {
    final l = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context:context,
      builder:(dialogContext)=>AlertDialog(
        title:Text(l.deleteExpense),
        content:Text(l.deleteExpenseWarning),
        actions:[
          TextButton(onPressed:()=>Navigator.pop(dialogContext,false),
            child:Text(l.cloudCancel)),
          FilledButton(onPressed:()=>Navigator.pop(dialogContext,true),
            child:Text(l.deleteExpense)),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      // Read linked object path before deleting its mapping. After the
      // financial RPC succeeds, remove storage as a best-effort cleanup.
      String? receiptPath;
      try {
        final link = await ReceiptStorage().get(
          expenseId:expense['id'] as String);
        receiptPath = link?['object_path'] as String?;
      } catch (_) {}
      await api.delete(groupId:widget.groupId,original:expense);
      if (receiptPath != null) {
        try {
          await Supabase.instance.client.storage
            .from(ReceiptStorage.bucket).remove([receiptPath]);
        } catch (_) {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content:Text(l.expenseReceiptCleanupWarning)));
        }
      }
      if (mounted) await refresh();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content:Text(e.toString())));
    }
  }

  Future<void> showQueuedExpense(Map<String,Object?> item) async {
    final l=AppLocalizations.of(context)!;
    await showModalBottomSheet<void>(
      context:context,showDragHandle:true,useSafeArea:true,
      builder:(ctx)=>Padding(
        padding:const EdgeInsets.fromLTRB(20,8,20,26),
        child:Column(mainAxisSize:MainAxisSize.min,
          crossAxisAlignment:CrossAxisAlignment.start,children:[
            Text(item['title'] as String,
              style:Theme.of(context).textTheme.titleLarge),
            const SizedBox(height:12),
            Text('${item['currency']} ${item['amount']}'),
            const SizedBox(height:12),
            Text(l.offlinePendingDetails,
              style:Theme.of(context).textTheme.bodySmall),
            if (item['last_error'] != null) ...[
              const SizedBox(height:12),
              SelectableText(item['last_error'] as String,
                style:Theme.of(context).textTheme.bodySmall),
            ],
          ]),
      ),
    );
  }

  Future<void> showCachedExpense(Map<String,dynamic> expense) async {
    final l = AppLocalizations.of(context)!;
    await showModalBottomSheet<void>(
      context:context, showDragHandle:true, useSafeArea:true,
      builder:(sheetContext)=>Padding(
        padding:const EdgeInsets.fromLTRB(20,8,20,30),
        child:Column(mainAxisSize:MainAxisSize.min,
          crossAxisAlignment:CrossAxisAlignment.start,children:[
          Text(expense['title'] as String,
            style:Theme.of(context).textTheme.titleLarge),
          const SizedBox(height:12),
          Text('${expense['currency']} ${(expense['amount'] as num).toStringAsFixed(2)}',
            style:Theme.of(context).textTheme.titleMedium),
          const SizedBox(height:8),
          Text(l.paidBy + ': ' +
            memberName(expense['paid_by'] as String?)),
          const SizedBox(height:12),
          Text(l.offlineReadOnlyDetails,
            style:Theme.of(context).textTheme.bodySmall),
        ]),
      ),
    );
  }

  Future<void> showShares(Map<String, dynamic> expense) async {
    final l = AppLocalizations.of(context)!;
    await showModalBottomSheet<void>(
      context: context, isScrollControlled: true, showDragHandle: true,
      builder: (_) => FutureBuilder<List<Map<String, dynamic>>>(
        future: api.shares(expense['id'] as String),
        builder: (context, snapshot) => SafeArea(child: SingleChildScrollView(
          child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 26),
          child: Column(mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(expense['title'] as String,
                style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(l.paidBy + ': ' + memberName(expense['paid_by'] as String?)),
              if ((expense['currency'] as String? ?? widget.currency) != widget.currency) ...[
                const SizedBox(height: 8),
                Text(l.expenseRateToGroup + ': 1 ' +
                  (expense['currency'] as String) + ' = ' +
                  (expense['rate_to_spending'] as num).toString() + ' ' +
                  widget.currency,
                  style: Theme.of(context).textTheme.bodySmall),
              ],
              if (expense['receipt_date'] != null) ...[
                const SizedBox(height: 8),
                Text(l.expenseReceiptDate + ': ' +
                  (expense['receipt_date'] as String),
                  style: Theme.of(context).textTheme.bodySmall),
              ],
              ReceiptAttachmentPreview(expenseId: expense['id'] as String),
              if (expense['created_by'] ==
                  Supabase.instance.client.auth.currentUser?.id) ...[
                const SizedBox(height: 10),
                Wrap(spacing:8,runSpacing:8,children:[
                  OutlinedButton.icon(
                    onPressed:(){
                      Navigator.pop(context);
                      editExpense(expense);
                    },
                    icon:const Icon(Icons.edit_outlined),
                    label:Text(l.editExpense),
                  ),
                  TextButton.icon(
                    onPressed:(){
                      Navigator.pop(context);
                      deleteExpense(expense);
                    },
                    icon:const Icon(Icons.delete_outline),
                    label:Text(l.deleteExpense),
                  ),
                ]),
              ],
              const SizedBox(height: 18),
              if (snapshot.connectionState != ConnectionState.done)
                const Center(child: CircularProgressIndicator())
              else if (snapshot.hasError)
                Text(snapshot.error.toString(), style: TextStyle(
                  color: Theme.of(context).colorScheme.error))
              else
                for (final share in snapshot.data ?? [])
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(memberName(share['user_id'] as String?)),
                    trailing: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text((expense['currency'] as String? ?? widget.currency) +
                          ' ' + (share['share_amount'] as num).toStringAsFixed(2),
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                        if ((expense['currency'] as String? ?? widget.currency)
                            != widget.currency)
                          Text(widget.currency + ' ' +
                            (share['share_spending'] as num).toStringAsFixed(2),
                            style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
            ]),
        ))),
      ),
    );
  }

  Future<void> editFundPurchase(Map<String,dynamic> entry) async {
    final changed=await Navigator.push<bool>(context,MaterialPageRoute(
      builder:(_)=>FundPurchaseEditPage(
        groupId:widget.groupId,
        groupCurrency:widget.currency,
        entry:entry,
      ),
    ));
    if(mounted && changed==true) await refresh();
  }

  Future<void> deleteFundPurchase(Map<String,dynamic> entry) async {
    final l=AppLocalizations.of(context)!;
    final confirmed=await showDialog<bool>(context:context,
      builder:(ctx)=>AlertDialog(
        title:Text(l.deleteExpense),
        content:Text(l.fundPurchaseDeleteWarning),
        actions:[
          TextButton(onPressed:()=>Navigator.pop(ctx,false),
            child:Text(l.cloudCancel)),
          FilledButton(onPressed:()=>Navigator.pop(ctx,true),
            child:Text(l.deleteExpense)),
        ],
      ),
    );
    if(confirmed!=true || !mounted) return;
    try {
      String? receiptPath;
      try {
        final link=await ReceiptStorage().get(
          fundEntryId:entry['id'] as String);
        receiptPath=link?['object_path'] as String?;
      } catch (_) {}
      await api.correctFundPurchase(groupId:widget.groupId,entry:entry);
      if(receiptPath!=null) {
        try {
          await Supabase.instance.client.storage.from(ReceiptStorage.bucket)
            .remove([receiptPath]);
        } catch (_) {
          if(mounted) ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content:Text(l.expenseReceiptCleanupWarning)));
        }
      }
      if(mounted) await refresh();
    } catch(e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content:Text(e.toString())));
    }
  }

  Future<void> showFundReceipt(Map<String,dynamic> entry) async {
    final l=AppLocalizations.of(context)!;
    final originalCurrency=entry['original_currency'] as String? ??
      widget.currency;
    final originalAmount=(entry['original_amount'] ?? entry['amount']) as num;
    final groupAmount=(entry['amount'] as num);
    final canEdit=!showingOfflineSnapshot &&
      entry['recorded_by']==Supabase.instance.client.auth.currentUser?.id;
    await showModalBottomSheet<void>(
      context:context,isScrollControlled:true,useSafeArea:true,
      showDragHandle:true,
      builder:(sheetContext)=>FractionallySizedBox(
        heightFactor:0.66,
        child:SingleChildScrollView(
          padding:const EdgeInsets.fromLTRB(20,4,20,32),
          child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            Row(children:[
              Icon(Icons.account_balance_wallet_outlined,
                color:Theme.of(sheetContext).colorScheme.primary),
              const SizedBox(width:10),
              Expanded(child:Text(l.fundPaidFromPool,
                style:Theme.of(sheetContext).textTheme.titleMedium)),
            ]),
            const SizedBox(height:16),
            Text(entry['description'] as String,
              style:Theme.of(sheetContext).textTheme.headlineSmall
                ?.copyWith(fontWeight:FontWeight.w700)),
            const SizedBox(height:12),
            Text('$'+'{originalCurrency} '+'$'+'{originalAmount.toStringAsFixed(2)}',
              style:Theme.of(sheetContext).textTheme.titleLarge),
            if(originalCurrency!=widget.currency) ...[
              const SizedBox(height:6),
              Text('$'+'{l.groupEquivalent}: '+'$'+'{widget.currency} '+
                groupAmount.toStringAsFixed(2)),
              const SizedBox(height:6),
              Text('$'+'{l.expenseRateToGroup}: 1 '+
                originalCurrency+' = '+
                (entry['rate_to_spending'] as num?)?.toString() .toString()+
                ' '+widget.currency),
            ],
            const SizedBox(height:10),
            if(entry['receipt_date'] != null)
              Text('$'+'{l.expenseReceiptDate}: '+
                (entry['receipt_date'] as String)),
            const SizedBox(height:12),
            ReceiptAttachmentPreview(fundEntryId:entry['id'] as String),
            if(canEdit) ...[
              const SizedBox(height:18),
              Wrap(spacing:10,runSpacing:8,children:[
                OutlinedButton.icon(
                  onPressed:(){
                    Navigator.pop(sheetContext);
                    editFundPurchase(entry);
                  },
                  icon:const Icon(Icons.edit_outlined),
                  label:Text(l.editExpense)),
                TextButton.icon(
                  onPressed:(){
                    Navigator.pop(sheetContext);
                    deleteFundPurchase(entry);
                  },
                  icon:const Icon(Icons.delete_outline),
                  label:Text(l.deleteExpense)),
              ]),
            ],
            if(!canEdit)
              Text(l.fundPurchaseAuthorOnly,
                style:Theme.of(sheetContext).textTheme.bodySmall),
          ]),
        ),
      ),
    );
  }

  @override Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(l.expenses),
        actions: [IconButton(onPressed: busy ? null : refresh,
          icon: const Icon(Icons.refresh_rounded), tooltip: l.cloudRefresh)]),
      body: SafeArea(top: false, child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          const SizedBox(height: 6),
          FilledButton.icon(
            onPressed: widget.members.isEmpty || busy ? null : createExpense,
            icon: const Icon(Icons.add_rounded), label: Text(l.addExpense)),
          const SizedBox(height: 16),
          if (showingOfflineSnapshot)
            Padding(
              padding: const EdgeInsets.only(bottom:12),
              child: Row(children:[
                Icon(Icons.wifi_off_rounded, color: scheme.onSurfaceVariant),
                const SizedBox(width:8),
                Expanded(child: Text(l.offlineReadOnlySnapshot,
                  style:Theme.of(context).textTheme.bodySmall)),
              ]),
            ),
          if (queuedExpenses.isNotEmpty) ...[
            Row(children: [
              Icon(Icons.cloud_upload_outlined, size: 21,
                color: scheme.primary),
              const SizedBox(width: 8),
              Expanded(child: Text(l.offlinePendingHeading,
                style: Theme.of(context).textTheme.titleMedium)),
              TextButton.icon(onPressed: busy ? null : refresh,
                icon: const Icon(Icons.sync_rounded),
                label: Text(l.offlineRetry)),
            ]),
            const SizedBox(height: 6),
            for (final item in queuedExpenses) ...[
              Card(child: ListTile(
                leading: Icon(item['status'] == 'needs_review'
                    ? Icons.error_outline : Icons.schedule_rounded,
                  color: item['status'] == 'needs_review'
                    ? scheme.error : scheme.primary),
                title: Text(item['title'] as String),
                subtitle: Text(item['status'] == 'receipt_pending'
                  ? l.offlineReceiptPending
                  : item['status'] == 'needs_review'
                    ? l.offlineNeedsReview
                    : l.offlinePending),
                trailing: Text('${item['currency']} ${item['amount']}',
                  style: const TextStyle(fontWeight: FontWeight.w700)),
                onTap: () => showQueuedExpense(item),
              )),
              const SizedBox(height: 8),
            ],
            const Divider(height: 20),
          ],
          if (busy) const Center(child: CircularProgressIndicator()),
          if (error != null) Text(error!, style: TextStyle(color: scheme.error)),
          if (!busy && error == null &&
              expenses.isEmpty && fundPurchases.isEmpty &&
              queuedExpenses.isEmpty)
            Card(child: Padding(padding: const EdgeInsets.all(24),
              child: Text(l.noExpenses, textAlign: TextAlign.center))),
          for (final purchase in fundPurchases) ...[
            LuiFeatureTile(
              icon: Icons.account_balance_wallet_outlined,
              title: purchase['description'] as String,
              subtitle: l.paidBy + ': ' + l.fund +
                  ((purchase['original_currency'] as String?) != null &&
                    purchase['original_currency'] != widget.currency
                    ? ' · ' + (purchase['original_currency'] as String) +
                      ' ' + (purchase['original_amount'] as num).toStringAsFixed(2)
                    : ''),
              trailing: Text(widget.currency + ' ' +
                (purchase['amount'] as num).toStringAsFixed(2),
                style: const TextStyle(fontWeight: FontWeight.w700)),
              onTap: () => showFundReceipt(purchase),
            ),
            const SizedBox(height: 10),
          ],
          for (final expense in expenses) ...[
            LuiFeatureTile(
              icon: Icons.receipt_long_outlined,
              title: expense['title'] as String,
              subtitle: l.paidBy + ': ' +
                memberName(expense['paid_by'] as String?),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text((expense['currency'] as String? ?? widget.currency) +
                    ' ' + (expense['amount'] as num).toStringAsFixed(2),
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                  if ((expense['currency'] as String? ?? widget.currency)
                    != widget.currency)
                    Text(widget.currency + ' ' +
                      (expense['amount_spending'] as num).toStringAsFixed(2),
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
              onTap: () => showingOfflineSnapshot
                ? showCachedExpense(expense) : showShares(expense),
            ),
            const SizedBox(height: 10),
          ],
        ])),
    );
  }
}

class AddSharedExpensePage extends StatefulWidget {
  const AddSharedExpensePage({
    super.key, required this.api, required this.groupId,
    required this.currency, required this.members,
    required this.groupRate, required this.settlementCurrency,
    this.initialExpense,
  });
  final Map<String,dynamic>? initialExpense;
  final SharedExpenseApi api;
  final String groupId, currency, settlementCurrency;
  final double groupRate;
  final List<Map<String, dynamic>> members;
  @override State<AddSharedExpensePage> createState() => _AddSharedExpensePageState();
}

class _AddSharedExpensePageState extends State<AddSharedExpensePage> {
  final form = GlobalKey<FormState>();
  final title = TextEditingController();
  final amount = TextEditingController();
  final selected = <String>{};
  final exchangeRate = TextEditingController();
  static const currencies = [
    'SGD','JPY','MYR','THB','USD','EUR','GBP','KRW','TWD','IDR','CNY','AUD',
  ];
  String? payer;
  bool payFromFund = false;
  double? fundAvailable;
  bool fundLoading = true;
  late String expenseCurrency;
  bool saving = false;
  bool readingReceipt = false;
  bool existingSharesLoading = false;
  DateTime? receiptDate;
  bool currencyManuallySet = false;
  ReceiptDraft? receipt;
  final receiptStorage = ReceiptStorage();

  Future<void> chooseReceipt(ImageSource source) async {
    if (saving || readingReceipt) return;
    setState(() => readingReceipt = true);
    try {
      final picked = await ReceiptCapture.choose(source);
      if (!mounted || picked == null) return;
      setState(() {
        receipt = picked;
        // Never overwrite a user-entered value.
        if (amount.text.trim().isEmpty && picked.suggestedTotal != null) {
          amount.text = picked.suggestedTotal!;
        }
        if (title.text.trim().isEmpty && picked.hints.merchant != null) {
          title.text = picked.hints.merchant!;
        }
        final detected = picked.hints.currency;
        if (!currencyManuallySet && detected != null &&
            currencies.contains(detected) && detected != expenseCurrency) {
          expenseCurrency = detected;
          exchangeRate.text = detected == widget.currency
            ? '1' : detected == widget.settlementCurrency
              ? widget.groupRate.toString() : '';
        }
        receiptDate ??= picked.hints.date;
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => readingReceipt = false);
    }
  }

  @override void initState() {
    super.initState();
    final original = widget.initialExpense;
    expenseCurrency = original?['currency'] as String? ?? widget.currency;
    if (!currencies.contains(expenseCurrency)) expenseCurrency = widget.currency;
    exchangeRate.text = original?['rate_to_spending']?.toString() ?? '1';
    if (original != null) {
      title.text = original['title'] as String? ?? '';
      amount.text = (original['amount'] as num).toStringAsFixed(2);
      final dateText = original['receipt_date'] as String?;
      receiptDate = dateText == null ? null : DateTime.tryParse(dateText);
      currencyManuallySet = true;
    }
    final ownId = Supabase.instance.client.auth.currentUser?.id;
    payer = widget.members.any((m) => m['user_id'] == ownId)
      ? ownId : (widget.members.isEmpty ? null :
          widget.members.first['user_id'] as String);
    if (widget.initialExpense == null) {
      selected.addAll(widget.members.map((m) => m['user_id'] as String));
      loadFund();
    } else {
      payer = widget.initialExpense!['paid_by'] as String;
      fundLoading = false;
      existingSharesLoading = true;
      loadExistingShares();
    }
  }

  Future<void> loadExistingShares() async {
    try {
      final shares = await widget.api.shares(widget.initialExpense!['id'] as String);
      if (mounted) setState(() {
        selected..clear()..addAll(shares.map((x) => x['user_id'] as String));
        existingSharesLoading = false;
      });
    } catch (e) {
      if (mounted) {
        // Do not allow saving an incomplete split when the read fails.
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> chooseReceiptDate() async {
    final picked = await showDatePicker(
      context:context,
      firstDate:DateTime(1990),
      lastDate:DateTime.now().add(const Duration(days:1)),
      initialDate:receiptDate ?? DateTime.now());
    if (picked != null && mounted) setState(() => receiptDate = picked);
  }

  Future<void> loadFund() async {
    try {
      final data = await widget.api.fundBalance(widget.groupId);
      if (mounted) setState(() {
        fundAvailable = (data?['balance'] as num?)?.toDouble() ?? 0;
        fundLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() {fundAvailable = 0;fundLoading = false;});
    }
  }

  @override void dispose() {
    title.dispose(); amount.dispose(); exchangeRate.dispose(); super.dispose();
  }

  Future<void> save() async {
    if (saving || existingSharesLoading ||
        !(form.currentState?.validate() ?? false)) return;
    final l = AppLocalizations.of(context)!;
    if (!payFromFund && (selected.isEmpty || payer == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.selectParticipants)));
      return;
    }
    if (payFromFund &&
        (convertedAmount == null || convertedAmount! > (fundAvailable ?? 0))) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.expenseFundInsufficient)));
      return;
    }
    setState(() => saving = true);
    try {
      if (widget.initialExpense != null) {
        await widget.api.edit(
          groupId:widget.groupId,
          original:widget.initialExpense!,
          title:title.text,
          amount:double.parse(amount.text.trim()),
          currency:expenseCurrency,
          rateToSpending:expenseCurrency == widget.currency
            ? 1 : double.parse(exchangeRate.text.trim()),
          paidBy:payer!,
          participants:widget.members.map((m)=>m['user_id'] as String)
            .where(selected.contains).toList(),
          receiptDate:receiptDate,
        );
        if (mounted) Navigator.pop(context,true);
        return;
      }
      if (!payFromFund) {
        // Offline-first: save to durable SQLite before navigating away.
        // One immutable UUID is used for every server retry.
        await OfflineExpenseOutbox.instance.queue(
          groupId: widget.groupId,
          title: title.text,
          amount: amount.text.trim(),
          currency: expenseCurrency,
          rateToSpending: expenseCurrency == widget.currency
            ? '1' : exchangeRate.text.trim(),
          paidBy: payer!,
          participants: widget.members
            .map((m) => m['user_id'] as String)
            .where(selected.contains).toList(),
          receipt: receipt?.jpeg,
          receiptDate: receiptDate,
        );
        if (mounted) Navigator.pop(context, true);
        return;
      }
      String createdId;
      if (payFromFund) {
        createdId = await widget.api.addFundPurchase(
          groupId: widget.groupId,
          title: title.text,
          amount: double.parse(amount.text.trim()),
          currency: expenseCurrency,
          rateToSpending: expenseCurrency == widget.currency
              ? 1 : double.parse(exchangeRate.text.trim()),
        );
      } else {
        createdId = await widget.api.add(
          groupId: widget.groupId,
          title: title.text,
          amount: double.parse(amount.text.trim()),
          currency: expenseCurrency,
          rateToSpending: expenseCurrency == widget.currency
              ? 1 : double.parse(exchangeRate.text.trim()),
          paidBy: payer!,
          splitBetween: widget.members
              .map((m) => m['user_id'] as String)
              .where(selected.contains).toList(),
        );
      }
      if (receiptDate != null) {
        // Metadata is separate for compatibility with existing expense RPCs.
        // Do not attempt to re-create a committed expense if this fails.
        try {
          await widget.api.saveReceiptDate(
            groupId:widget.groupId, date:receiptDate,
            expenseId:payFromFund ? null : createdId,
            fundEntryId:payFromFund ? createdId : null,
          );
        } catch (_) { /* Expense remains safely recorded. */ }
      }
      // The expense is already committed. A failed receipt upload must not
      // tempt users to create a duplicate charge by pressing Save again.
      if (receipt != null) {
        try {
          await receiptStorage.upload(
            groupId: widget.groupId,
            jpeg: receipt!.jpeg,
            expenseId: payFromFund ? null : createdId,
            fundEntryId: payFromFund ? createdId : null,
          );
        } catch (_) {
          if (mounted) {
            final messenger = ScaffoldMessenger.of(context);
            final message = l.receiptUploadFailed;
            Navigator.pop(context, true);
            messenger.showSnackBar(SnackBar(content: Text(message)));
          }
          return;
        }
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  void chooseCurrency(String? value) {
    if (value == null) return;
    setState(() {
      expenseCurrency = value;
      currencyManuallySet = true;
      exchangeRate.text = value == widget.currency
        ? '1'
        : value == widget.settlementCurrency
          ? widget.groupRate.toString()
          : '';
    });
  }

  double? get convertedAmount {
    final original = double.tryParse(amount.text.trim());
    final rate = expenseCurrency == widget.currency
      ? 1.0 : double.tryParse(exchangeRate.text.trim());
    if (original == null || rate == null || !original.isFinite ||
      !rate.isFinite || original <= 0 || rate <= 0) return null;
    final converted = original * rate;
    if (!converted.isFinite || converted <= 0 ||
      converted > 9999999999999999) return null;
    return (converted * 100).round() / 100;
  }

  @override Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(
        widget.initialExpense == null ? l.addExpense : l.editExpense)),
      body: SafeArea(top: false, child: Form(key: form,
        child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40), children: [
          LuiFormLabel(l.expenseTitle),
          TextFormField(
            controller: title, maxLength: 120,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(hintText: l.expenseTitleHint),
            validator: (v) => (v ?? '').trim().isEmpty ? l.required : null),
          const SizedBox(height: 16),
          LuiFormLabel(l.expenseCurrency),
          DropdownButtonFormField<String>(
            value: expenseCurrency,
            isExpanded: true,
            decoration: const InputDecoration(),
            items: currencies.map((c) =>
              DropdownMenuItem(value: c, child: Text(c))).toList(),
            onChanged: saving ? null : chooseCurrency,
          ),
          const SizedBox(height: 18),
          LuiFormLabel(l.expenseAmount),
          TextFormField(
            controller: amount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(prefixText: expenseCurrency + ' '),
            onChanged: (_) => setState(() {}),
            validator: (v) {
              final raw = (v ?? '').trim();
              final n = double.tryParse(raw);
              if (!RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(raw) ||
                  n == null || !n.isFinite || n <= 0 ||
                  n > 9999999999999999) return l.invalid;
              return null;
            },
          ),
          const SizedBox(height: 18),
          if (expenseCurrency != widget.currency) ...[
            const SizedBox(height: 6),
            LuiFormLabel(l.expenseRateToGroup),
            TextFormField(
              controller: exchangeRate,
              keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                helperText: '1 ' + expenseCurrency + ' = ? ' + widget.currency,
                helperMaxLines: 2,
              ),
              validator: (v) {
                final text = (v ?? '').trim();
                final n = double.tryParse(text);
                if (!RegExp(r'^\d+(\.\d{1,8})?$').hasMatch(text)
                    || n == null || !n.isFinite || n <= 0
                    || n > 99999999999999) return l.invalid;
                return null;
              },
            ),
            const SizedBox(height: 10),
            if (convertedAmount != null)
              Text(l.groupEquivalent + ': ' + widget.currency + ' ' +
                convertedAmount!.toStringAsFixed(2),
                style: Theme.of(context).textTheme.bodyMedium),
          ],
          const SizedBox(height: 16),
          LuiFormLabel(l.expenseReceiptDate),
          OutlinedButton.icon(
            onPressed:saving ? null : chooseReceiptDate,
            icon:const Icon(Icons.calendar_today_outlined),
            label:Text(receiptDate == null ? l.expenseChooseDate :
              '${receiptDate!.day.toString().padLeft(2,'0')}/'
              '${receiptDate!.month.toString().padLeft(2,'0')}/'
              '${receiptDate!.year}'),
          ),
          const SizedBox(height: 22),
          if (widget.initialExpense == null)
          LuiFormLabel(l.receiptAttachment),
          if (widget.initialExpense == null)
          Card(child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (receipt != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.memory(receipt!.jpeg,
                      height: 180, fit: BoxFit.contain)),
                  const SizedBox(height: 8),
                  Text(l.receiptReviewHint,
                    style: Theme.of(context).textTheme.bodySmall),
                  TextButton.icon(
                    onPressed: saving ? null :
                      () => setState(() => receipt = null),
                    icon: const Icon(Icons.close_rounded),
                    label: Text(l.receiptRemove),
                  ),
                ],
                if (readingReceipt)
                  const Center(child: CircularProgressIndicator()),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  OutlinedButton.icon(
                    onPressed: saving || readingReceipt ? null :
                      () => chooseReceipt(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: Text(l.receiptCamera)),
                  OutlinedButton.icon(
                    onPressed: saving || readingReceipt ? null :
                      () => chooseReceipt(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_outlined),
                    label: Text(l.receiptGallery)),
                ]),
              ]),
          )),
          const SizedBox(height: 22),
          LuiFormLabel(l.paidBy),
          if (widget.initialExpense == null &&
              !fundLoading && (fundAvailable ?? 0) > 0) ...[
            Card(child: SwitchListTile.adaptive(
              title: Text(l.fund),
              subtitle: Text(l.expenseFundAvailable + ': ' +
                widget.currency + ' ' + fundAvailable!.toStringAsFixed(2)),
              value: payFromFund,
              onChanged: saving ? null :
                (value) => setState(() => payFromFund = value),
            )),
            const SizedBox(height: 12),
          ],
          if (!payFromFund) DropdownButtonFormField<String>(
            value: payer, isExpanded: true,
            decoration: const InputDecoration(),
            items: widget.members.map((m) => DropdownMenuItem(
              value: m['user_id'] as String,
              child: Text(m['nickname'] as String))).toList(),
            onChanged: saving ? null : (v) => setState(() => payer = v),
          ),
          if (payFromFund && convertedAmount != null &&
              convertedAmount! > (fundAvailable ?? 0)) ...[
            const SizedBox(height: 8),
            Text(l.expenseFundInsufficient,
              style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
          if (!payFromFund) ...[
          const SizedBox(height: 24),
          LuiFormLabel(l.splitBetween),
          Card(child: Column(children: [
            for (var i = 0; i < widget.members.length; i++) ...[
              if (i > 0) const Divider(height: 1, indent: 16),
              CheckboxListTile(
                value: selected.contains(widget.members[i]['user_id']),
                title: Text(widget.members[i]['nickname'] as String),
                controlAffinity: ListTileControlAffinity.trailing,
                onChanged: saving ? null : (checked) => setState(() {
                  final id = widget.members[i]['user_id'] as String;
                  if (checked == true) { selected.add(id); }
                  else { selected.remove(id); }
                }),
              ),
            ],
          ])),
          const SizedBox(height: 12),
          Text(l.equalSplitOnly,
            style: Theme.of(context).textTheme.bodySmall),
          ],
          if (payFromFund) ...[
            const SizedBox(height: 12),
            Text(l.expenseFundNoSplit,
              style: Theme.of(context).textTheme.bodySmall),
          ],
          if (expenseCurrency != widget.currency) ...[
            const SizedBox(height: 8),
            Text(l.expenseConversionHint,
              style: Theme.of(context).textTheme.bodySmall),
          ],
          const SizedBox(height: 28),
          FilledButton(
            onPressed: saving || existingSharesLoading ? null : save,
            child: saving
              ? const SizedBox(height: 20, width: 20,
                child: CircularProgressIndicator(strokeWidth: 2))
              : Text(widget.initialExpense == null
                ? l.saveExpense : l.saveChanges),
          ),
        ]),
      )),
    );
  }
}
