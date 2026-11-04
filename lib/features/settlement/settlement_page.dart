import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../ui/lui_style.dart';
import 'settlement_calculator.dart';
import 'expense_currency_summary.dart';
import 'paynow_settings_page.dart';
import 'repayment_preferences.dart';

/// Settlement preview only: no transfer is executed or marked as paid.
class SettlementPage extends StatefulWidget {
  const SettlementPage({
    super.key, required this.groupId, required this.groupName,
    required this.spendingCurrency, required this.settlementCurrency,
    required this.exchangeRate, required this.members,
  });

  final String groupId, groupName, spendingCurrency, settlementCurrency;
  final double exchangeRate;
  final List<Map<String, dynamic>> members;

  @override State<SettlementPage> createState() => _SettlementPageState();
}

class _SettlementPageState extends State<SettlementPage> {
  bool busy = true;
  String? error;
  SettlementResult? result;
  ExpenseCurrencySummary? expenseSummary;
  List<Map<String, dynamic>> repayments = [];
  Map<String,String> payNowMobiles = {};
  final payNowApi = GroupPayNowApi();

  @override
  void initState() {
    super.initState();
    refresh();
  }

  String nameOf(String id) {
    for (final m in widget.members) {
      if (m['user_id'] == id) return m['nickname'] as String? ?? id;
    }
    return id;
  }

  Future<List<Map<String, dynamic>>> readAll(String table,
      String columns) async {
    final db = Supabase.instance.client;
    const pageSize = 500;
    final rows = <Map<String, dynamic>>[];
    var offset = 0;
    while (true) {
      // Explicit paging avoids PostgREST's default maximum 1000 rows.
      final page = await db.from(table).select(columns)
          .eq('group_id', widget.groupId)
          .order(table == 'trip_expense_shares' ? 'expense_id' : 'created_at', ascending: false)
          .order(table == 'trip_expense_shares' ? 'user_id' : 'id')
          .range(offset, offset + pageSize - 1);
      rows.addAll(page.map((item) => Map<String, dynamic>.from(item)));
      if (page.length < pageSize) break;
      offset += pageSize;
    }
    return rows;
  }

  Future<void> refresh() async {
    if (mounted) setState(() { busy = true; error = null; });
    try {
      final expenses = await readAll('trip_expenses',
          'id,paid_by,amount,currency,amount_spending');
      final shares = await readAll('trip_expense_shares',
          'expense_id,user_id,share_spending');
      final receiptRows = await readAll('trip_repayments',
        'id,from_user_id,to_user_id,amount_spending,paid_amount,paid_currency,paid_rate_to_spending,note,created_at,reversed_at,reversal_reason');
      final payNowRows = await payNowApi.getAll(widget.groupId);
      final summary = ExpenseCurrencySummary.calculate(
        expenses: expenses,
        spendingCurrency: widget.spendingCurrency,
        settlementCurrency: widget.settlementCurrency,
        spendingPerSettlement: widget.exchangeRate,
      );
      final calculated = SettlementCalculator.calculate(
        memberIds: widget.members.map((m) => m['user_id'] as String).toList(),
        expenses: expenses,
        shares: shares,
        repayments: receiptRows.where(
          (row) => row['reversed_at'] == null).toList(),
      );
      if (mounted) setState(() {
        result = calculated;
        expenseSummary = summary;
        repayments = receiptRows;
        payNowMobiles = payNowRows;
      });
    } catch (e) {
      if (mounted) setState(() {
        error = e.toString();
        result = null;
        expenseSummary = null;
      });
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> recordReceipt(SuggestedTransfer transfer) async {
    final recorded = await Navigator.push<bool>(context, MaterialPageRoute(
      builder: (_) => RepaymentReceiptForm(
        groupId: widget.groupId,
        spendingCurrency: widget.spendingCurrency,
        settlementCurrency: widget.settlementCurrency,
        groupRate: widget.exchangeRate,
        senderName: nameOf(transfer.fromUserId),
        receiverName: nameOf(transfer.toUserId),
        fromUserId: transfer.fromUserId,
        toUserId: transfer.toUserId,
        maxCents: transfer.cents,
      ),
    ));
    if (mounted && recorded == true) await refresh();
  }

  Future<void> reverseReceipt(Map<String,dynamic> receipt) async {
    final l = AppLocalizations.of(context)!;
    final reason = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => _RepaymentReversalSheet(),
    );
    if (reason == null || !mounted) return;
    setState(() => busy = true);
    try {
      await Supabase.instance.client.rpc('reverse_trip_repayment', params: {
        'p_group': widget.groupId,
        'p_receipt': receipt['id'],
        'p_reason': reason,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.repaymentReversed)));
        await refresh();
      }
    } catch(e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> editPayNow() async {
    final updated = await Navigator.push<bool>(context, MaterialPageRoute(
      builder: (_) => PayNowSettingsPage(
        groupId: widget.groupId,
        groupName: widget.groupName,
      ),
    ));
    if (mounted && updated == true) await refresh();
  }

  bool get hasAlternateCurrency =>
    widget.spendingCurrency != widget.settlementCurrency &&
    widget.exchangeRate.isFinite && widget.exchangeRate > 0;

  String shownAmount(int cents) {
    if (hasAlternateCurrency) {
      return '≈ ' + widget.settlementCurrency + ' ' +
        (cents / 100 / widget.exchangeRate).toStringAsFixed(2);
    }
    return amount(cents);
  }

  String repaymentMessage(SuggestedTransfer transfer, AppLocalizations l) {
    final recipient = nameOf(transfer.toUserId);
    final sender = nameOf(transfer.fromUserId);
    final phone = payNowMobiles[transfer.toUserId];
    final content = StringBuffer()
      ..writeln('SplitLui · ' + widget.groupName)
      ..writeln(l.payNowRequestTo + ': ' + sender)
      ..writeln(l.payNowRecipient + ': ' + recipient)
      ..writeln(l.payNowAmountDue + ': ' + shownAmount(transfer.cents));
    // Share only the amount to pay; no second currency or ledger jargon.
    if (phone != null && phone.isNotEmpty) {
      content
        ..writeln('PayNow: +65 ' + phone)
        ..writeln(l.payNowVerifyRecipient);
    } else {
      content.writeln(l.payNowNoDetailsShared);
    }
    if (widget.spendingCurrency != 'SGD' ||
        widget.settlementCurrency != 'SGD') {
      content.writeln(l.payNowAgreeSgd);
    }
    content.writeln(l.payNowNotPayment);
    return content.toString().trimRight();
  }

  Future<void> shareRequest(SuggestedTransfer transfer) async {
    final l = AppLocalizations.of(context)!;
    try {
      await SharePlus.instance.share(ShareParams(
        text: repaymentMessage(transfer,l),
      ));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> copyPayNow(String userId) async {
    final phone = payNowMobiles[userId];
    if (phone == null) return;
    await Clipboard.setData(ClipboardData(text: phone));
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.payNowCopied)));
  }

  List<String> get recipients {
    final ids = <String>[];
    for (final transfer in result?.transfers ?? <SuggestedTransfer>[]) {
      if (!ids.contains(transfer.toUserId)) ids.add(transfer.toUserId);
    }
    return ids;
  }

  List<SuggestedTransfer> transfersTo(String recipientId) =>
      (result?.transfers ?? <SuggestedTransfer>[])
          .where((transfer) => transfer.toUserId == recipientId)
          .toList();

  Widget recipientCard(String recipientId, AppLocalizations l) {
    final colors = Theme.of(context).colorScheme;
    final lines = transfersTo(recipientId);
    final totalCents = lines.fold<int>(
      0, (sum, transfer) => sum + transfer.cents);
    final payNow = payNowMobiles[recipientId];
    final myId = Supabase.instance.client.auth.currentUser?.id;
    final isRecipient = recipientId == myId;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            CircleAvatar(
              child: Text(nameOf(recipientId).isEmpty
                ? '?' : nameOf(recipientId)[0].toUpperCase())),
            const SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(nameOf(recipientId), style: Theme.of(context)
                  .textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                Text(l.payNowReceivesFrom,
                  style: Theme.of(context).textTheme.bodySmall),
              ],
            )),
            const SizedBox(width: 8),
            Flexible(child: Column(
              crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(shownAmount(totalCents),
                  textAlign: TextAlign.end,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700)),

              ],
            )),
          ]),
          const SizedBox(height: 12),
          if (payNow != null && payNow.isNotEmpty)
            Container(
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
              child: Row(children: [
                const Icon(Icons.account_balance_outlined, size: 19),
                const SizedBox(width: 10),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('PayNow', style: Theme.of(context).textTheme.labelSmall),
                    Text('+65 $payNow', style: const TextStyle(
                      fontWeight: FontWeight.w600)),
                  ],
                )),
                IconButton(
                  tooltip: l.payNowCopyNumber,
                  onPressed: () => copyPayNow(recipientId),
                  icon: const Icon(Icons.copy_outlined, size: 20),
                ),
              ]),
            )
          else
            Text(l.payNowNoDetailsShared,
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 12),
          for (var index = 0; index < lines.length; index++) ...[
            if (index > 0) const Divider(height: 24),
            Row(children: [
              Expanded(child: Text(l.payNowFromMember + ': ' +
                  nameOf(lines[index].fromUserId),
                style: Theme.of(context).textTheme.bodyMedium)),
              const SizedBox(width: 8),
              Text(shownAmount(lines[index].cents),
                style: const TextStyle(fontWeight: FontWeight.w600)),
            ]),
            if (isRecipient)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Wrap(spacing: 8, runSpacing: 6, children: [
                  OutlinedButton.icon(
                    onPressed: busy ? null : () => shareRequest(lines[index]),
                    icon: const Icon(Icons.share_outlined, size: 18),
                    label: Text(l.payNowShareRequest),
                  ),
                  TextButton.icon(
                    onPressed: busy ? null : () => recordReceipt(lines[index]),
                    icon: const Icon(Icons.check_circle_outline, size: 18),
                    label: Text(l.repaymentConfirmReceived),
                  ),
                ]),
              ),
          ],
        ]),
      ),
    );
  }

  String amount(int cents) =>
      widget.spendingCurrency + ' ' + (cents / 100).toStringAsFixed(2);

  String? settlementEstimate(int cents) {
    if (widget.settlementCurrency == widget.spendingCurrency) return null;
    if (!widget.exchangeRate.isFinite || widget.exchangeRate <= 0) return null;
    return '≈ ' + widget.settlementCurrency + ' ' +
        (cents / 100 / widget.exchangeRate).toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.settlementPreview),
        actions: [
          IconButton(
            tooltip: l.cloudRefresh,
            onPressed: busy ? null : refresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(top: false, child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        children: [
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: busy ? null : editPayNow,
            icon: const Icon(Icons.phone_iphone_outlined),
            label: Text(l.payNowDetails),
          ),
          const SizedBox(height: 18),
          if (busy) const Center(child: CircularProgressIndicator()),
          if (error != null) Card(child: Padding(
            padding: const EdgeInsets.all(18),
            child: Text(error!, style: TextStyle(color: colors.error)),
          )),
          if (!busy && result != null) ...[
            LuiSectionHeading(title: l.settlementSuggestedTransfers),
            const SizedBox(height: 10),
            if (result!.transfers.isEmpty)
              Card(child: Padding(
                padding: const EdgeInsets.all(22),
                child: Text(l.settlementAllEven,
                  textAlign: TextAlign.center),
              )),
            for (final recipientId in recipients) ...[
              recipientCard(recipientId, l),
              const SizedBox(height: 10),
            ],
            const SizedBox(height: 22),
            LuiSectionHeading(title: l.repaymentHistory),
            const SizedBox(height: 12),
            if (repayments.isEmpty)
              Text(l.repaymentNoRecords,
                style: Theme.of(context).textTheme.bodySmall),
            for (final receipt in repayments) ...[
              Card(child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Icon(receipt['reversed_at'] == null
                        ? Icons.task_alt_rounded
                        : Icons.undo_rounded,
                        color: receipt['reversed_at'] == null
                          ? colors.primary : colors.onSurfaceVariant),
                      const SizedBox(width: 10),
                      Expanded(child: Text(
                        nameOf(receipt['from_user_id'] as String) +
                        ' → ' + nameOf(receipt['to_user_id'] as String),
                        style: const TextStyle(fontWeight: FontWeight.w600))),
                      Text((receipt['paid_currency'] as String) + ' ' +
                        (receipt['paid_amount'] as num).toStringAsFixed(2),
                        style: TextStyle(
                          decoration: receipt['reversed_at'] != null
                            ? TextDecoration.lineThrough : null,
                          fontWeight: FontWeight.w700)),
                    ]),
                    const SizedBox(height: 6),
                    Text(receipt['reversed_at'] == null
                      ? l.repaymentReceivedRecorded
                      : l.repaymentReversed,
                      style: Theme.of(context).textTheme.bodySmall),
                    if ((receipt['note'] as String).isNotEmpty)
                      Text(receipt['note'] as String,
                        style: Theme.of(context).textTheme.bodySmall),

                    if (receipt['reversed_at'] != null)
                      Text(l.repaymentReversalReason + ': ' +
                        (receipt['reversal_reason'] as String? ?? ''),
                        style: Theme.of(context).textTheme.bodySmall),
                    if (receipt['reversed_at'] == null &&
                        receipt['to_user_id'] ==
                          Supabase.instance.client.auth.currentUser?.id)
                      Align(alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: busy ? null :
                            () => reverseReceipt(receipt),
                          icon: const Icon(Icons.undo_rounded, size: 18),
                          label: Text(l.repaymentUndo),
                        )),
                  ]),
              )),
              const SizedBox(height: 10),
            ],
            const SizedBox(height: 22),
            Card(child:ExpansionTile(
              leading:const Icon(Icons.receipt_long_outlined),
              title:Text(l.settlementMoreDetails),
              childrenPadding:const EdgeInsets.fromLTRB(14,0,14,16),
              children:[
                if (expenseSummary != null) ...[
                  Text(l.settlementTotalExpenses,
                    style:Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height:8),
                  for (final item in expenseSummary!.totals)
                    Padding(padding:const EdgeInsets.symmetric(vertical:4),
                      child:Row(children:[
                        Expanded(child:Text(item.currency)),
                        Text(item.currency + ' ' +
                          (item.cents/100).toStringAsFixed(2)),
                      ])),
                  const Divider(height:24),
                ],
                Text(l.settlementMemberBalances,
                  style:Theme.of(context).textTheme.titleSmall),
                const SizedBox(height:8),
                for (final balance in result!.balances)
                  ListTile(
                    dense:true,
                    contentPadding:EdgeInsets.zero,
                    title:Text(nameOf(balance.userId)),
                    subtitle:Text(balance.cents>0 ? l.settlementIsOwed
                      : balance.cents<0 ? l.settlementOwes
                      : l.settlementBalanced),
                    trailing:Text(shownAmount(balance.cents.abs()),
                      style:const TextStyle(fontWeight:FontWeight.w600)),
                  ),
              ],
            )),
            const SizedBox(height: 12),
          ],
        ],
      )),
    );
  }
}


class RepaymentReceiptForm extends StatefulWidget {
  const RepaymentReceiptForm({
    super.key,
    required this.groupId,
    required this.spendingCurrency,
    required this.settlementCurrency,
    required this.groupRate,
    required this.senderName,
    required this.receiverName,
    required this.fromUserId,
    required this.toUserId,
    required this.maxCents,
  });

  final String groupId, spendingCurrency, settlementCurrency;
  final String senderName, receiverName, fromUserId, toUserId;
  final double groupRate;
  final int maxCents;

  @override State<RepaymentReceiptForm> createState() =>
      _RepaymentReceiptFormState();
}

class _RepaymentReceiptFormState extends State<RepaymentReceiptForm> {
  final formKey = GlobalKey<FormState>();
  final paidAmount = TextEditingController();
  final rate = TextEditingController();
  final note = TextEditingController();
  String currency = 'SGD';
  bool saving = false;
  bool loading = true;

  List<String> get currencies => {
    ...RepaymentPreferences.currencies,
    widget.spendingCurrency,
    widget.settlementCurrency,
  }.toList();

  @override
  void initState() {
    super.initState();
    loadPreference();
  }

  Future<void> loadPreference() async {
    final saved = await RepaymentPreferences.getDefault();
    if (!mounted) return;
    setState(() {
      currency = saved;
      loading = false;
      applyCurrencyDefaults();
    });
  }

  void applyCurrencyDefaults() {
    final conversion = currentDefaultRate;
    rate.text = conversion == null ? '' : conversion.toString();
    if (conversion != null && conversion > 0) {
      // Prepopulate the approximate full balance. Recipients can overwrite it
      // with the amount actually received (including partial repayments).
      paidAmount.text = (widget.maxCents / 100 / conversion).toStringAsFixed(2);
    } else {
      paidAmount.clear();
    }
  }

  double? get currentDefaultRate {
    if (currency == widget.spendingCurrency) return 1;
    if (currency == widget.settlementCurrency &&
        widget.groupRate.isFinite && widget.groupRate > 0) {
      return widget.groupRate;
    }
    // SGD -> MYR (or vice versa) is not derived from a THB -> SGD rate.
    // Users must enter an agreed manual rate when not in the group pair.
    return null;
  }

  double? get spendingEquivalent {
    final value = double.tryParse(paidAmount.text.trim());
    final conversion = double.tryParse(rate.text.trim());
    if (value == null || conversion == null || !value.isFinite ||
        !conversion.isFinite || value <= 0 || conversion <= 0) return null;
    final spending = (value * conversion * 100).round() / 100;
    return spending.isFinite ? spending : null;
  }

  @override
  void dispose() {
    paidAmount.dispose();
    rate.dispose();
    note.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (saving || loading || !(formKey.currentState?.validate() ?? false)) {
      return;
    }
    setState(() => saving = true);
    try {
      await Supabase.instance.client.rpc(
        'record_trip_repayment_currency',
        params: {
          'p_group': widget.groupId,
          'p_from': widget.fromUserId,
          'p_to': widget.toUserId,
          'p_paid_amount': double.parse(paidAmount.text.trim()),
          'p_currency': currency,
          'p_rate_to_spending': double.parse(rate.text.trim()),
          'p_note': note.text.trim(),
        },
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l.repaymentConfirmReceived)),
      body: SafeArea(top: false, child: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
          children: [
            Text(widget.senderName + ' → ' + widget.receiverName,
              style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Text(l.repaymentActualReceivedHint,
              style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 20),
            LuiFormLabel(l.repaymentPaidCurrency),
            DropdownButtonFormField<String>(
              value: currency,
              isExpanded: true,
              items: currencies.map((c) =>
                DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: saving || loading ? null : (value) {
                if (value == null) return;
                setState(() {
                  currency = value;
                  applyCurrencyDefaults();
                });
              },
            ),
            const SizedBox(height: 20),
            LuiFormLabel(l.repaymentPaidAmount),
            TextFormField(
              controller: paidAmount,
              enabled: !loading && !saving,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(prefixText: currency + ' '),
              onChanged: (_) => setState(() {}),
              validator: (raw) {
                final value = (raw ?? '').trim();
                final parsed = double.tryParse(value);
                if (!RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(value) ||
                    parsed == null || !parsed.isFinite || parsed <= 0 ||
                    parsed > 99999999999999.99) return l.invalid;
                return null;
              },
            ),
            const SizedBox(height: 20),
            if (currentDefaultRate == null) ...[
              LuiFormLabel(l.repaymentConversionRate),
              TextFormField(
                controller: rate,
                enabled:!loading && !saving,
                keyboardType:const TextInputType.numberWithOptions(decimal:true),
                decoration:InputDecoration(
                  helperText:'1 ' + currency + ' = ? ' + widget.spendingCurrency),
                onChanged:(_)=>setState((){}),
                validator:(raw) {
                  final text=(raw??'').trim();
                  final parsed=double.tryParse(text);
                  if(!RegExp(r'^\d+(\.\d{1,8})?$').hasMatch(text)
                      ||parsed==null||!parsed.isFinite||parsed<=0
                      ||parsed>99999999999999)return l.invalid;
                  return null;
                },
              ),
            ],
            const SizedBox(height: 22),
            LuiFormLabel(l.repaymentNote),
            TextFormField(
              controller: note,
              maxLength: 120,
              decoration: InputDecoration(hintText: l.repaymentNoteHint),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: saving || loading ||
                spendingEquivalent == null || spendingEquivalent! <= 0
                ? null : save,
              icon: const Icon(Icons.verified_outlined),
              label: Text(l.repaymentConfirmReceived),
            ),
          ],
        ),
      )),
    );
  }
}


class _RepaymentReversalSheet extends StatefulWidget {
  @override State<_RepaymentReversalSheet> createState() =>
      _RepaymentReversalSheetState();
}

class _RepaymentReversalSheetState extends State<_RepaymentReversalSheet> {
  final reason = TextEditingController();
  final form = GlobalKey<FormState>();

  @override void dispose() {
    reason.dispose();
    super.dispose();
  }

  @override Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: Form(
          key: form,
          child: Column(mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text(l.repaymentUndo,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              Text(l.repaymentUndoWarning,
                style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 18),
              TextFormField(
                controller: reason,
                autofocus: true,
                maxLength: 120,
                decoration: InputDecoration(
                  labelText: l.repaymentReversalReason,
                  hintText: l.repaymentReversalReasonHint),
                validator: (value) {
                  final text = (value ?? '').trim();
                  return text.length < 3 ? l.repaymentReversalReasonInvalid
                    : null;
                },
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () {
                  if (form.currentState?.validate() == true) {
                    Navigator.pop(context, reason.text.trim());
                  }
                },
                child: Text(l.repaymentUndoConfirm)),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l.cloudCancel)),
            ]),
        ),
      ),
    );
  }
}
