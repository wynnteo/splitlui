import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../ui/lui_style.dart';
import 'settlement_calculator.dart';

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
  List<Map<String, dynamic>> repayments = [];

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
          'id,paid_by,amount_spending');
      final shares = await readAll('trip_expense_shares',
          'expense_id,user_id,share_spending');
      final receiptRows = await readAll('trip_repayments',
        'id,from_user_id,to_user_id,amount_spending,note,created_at');
      final calculated = SettlementCalculator.calculate(
        memberIds: widget.members.map((m) => m['user_id'] as String).toList(),
        expenses: expenses,
        shares: shares,
        repayments: receiptRows,
      );
      if (mounted) setState(() {
        result = calculated;
        repayments = receiptRows;
      });
    } catch (e) {
      if (mounted) setState(() { error = e.toString(); result = null; });
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> recordReceipt(SuggestedTransfer transfer) async {
    final recorded = await Navigator.push<bool>(context, MaterialPageRoute(
      builder: (_) => RepaymentReceiptForm(
        groupId: widget.groupId,
        currency: widget.spendingCurrency,
        senderName: nameOf(transfer.fromUserId),
        receiverName: nameOf(transfer.toUserId),
        fromUserId: transfer.fromUserId,
        toUserId: transfer.toUserId,
        maxCents: transfer.cents,
      ),
    ));
    if (mounted && recorded == true) await refresh();
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
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          Text(widget.groupName,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700, letterSpacing: -0.7)),
          const SizedBox(height: 10),
          Text(l.settlementExplanation,
            style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 18),
          if (widget.settlementCurrency != widget.spendingCurrency)
            Card(child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(l.settlementRateNote + ': 1 ' +
                widget.settlementCurrency + ' = ' +
                widget.exchangeRate.toString() + ' ' +
                widget.spendingCurrency),
            )),
          const SizedBox(height: 18),
          if (busy) const Center(child: CircularProgressIndicator()),
          if (error != null) Card(child: Padding(
            padding: const EdgeInsets.all(18),
            child: Text(error!, style: TextStyle(color: colors.error)),
          )),
          if (!busy && result != null) ...[
            Card(child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.settlementTotalExpenses,
                    style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 8),
                  Text(amount(result!.totalExpenseCents),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700)),
                ]),
            )),
            const SizedBox(height: 26),
            LuiSectionHeading(title: l.settlementSuggestedTransfers),
            const SizedBox(height: 10),
            if (result!.transfers.isEmpty)
              Card(child: Padding(
                padding: const EdgeInsets.all(22),
                child: Text(l.settlementAllEven,
                  textAlign: TextAlign.center),
              )),
            for (final transfer in result!.transfers) ...[
              Card(child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Icon(Icons.send_rounded, color: colors.primary),
                      const SizedBox(width: 12),
                      Expanded(child: Text(
                        nameOf(transfer.fromUserId) + ' → ' +
                        nameOf(transfer.toUserId),
                        style: const TextStyle(fontWeight: FontWeight.w600))),
                    ]),
                    const SizedBox(height: 12),
                    Text(amount(transfer.cents),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700)),
                    if (settlementEstimate(transfer.cents) != null)
                      Text(settlementEstimate(transfer.cents)!,
                        style: Theme.of(context).textTheme.bodySmall),
                    if (Supabase.instance.client.auth.currentUser?.id ==
                        transfer.toUserId) ...[
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: busy ? null : () => recordReceipt(transfer),
                        icon: const Icon(Icons.check_circle_outline),
                        label: Text(l.repaymentConfirmReceived),
                      ),
                    ],
                  ],
                ),
              )),
              const SizedBox(height: 10),
            ],
            const SizedBox(height: 22),
            LuiSectionHeading(title: l.repaymentHistory),
            const SizedBox(height: 12),
            if (repayments.isEmpty)
              Text(l.repaymentNoRecords,
                style: Theme.of(context).textTheme.bodySmall),
            for (final receipt in repayments) ...[
              LuiFeatureTile(
                icon: Icons.task_alt_rounded,
                title: nameOf(receipt['from_user_id'] as String) +
                    ' → ' + nameOf(receipt['to_user_id'] as String),
                subtitle: l.repaymentReceivedRecorded +
                  ((receipt['note'] as String).isEmpty
                    ? '' : ' · ' + (receipt['note'] as String)),
                trailing: Text(widget.spendingCurrency + ' ' +
                  (receipt['amount_spending'] as num).toStringAsFixed(2),
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
              const SizedBox(height: 10),
            ],
            const SizedBox(height: 22),
            LuiSectionHeading(title: l.settlementMemberBalances),
            const SizedBox(height: 12),
            for (final balance in result!.balances) ...[
              LuiFeatureTile(
                icon: Icons.person_outline_rounded,
                title: nameOf(balance.userId),
                subtitle: balance.cents > 0
                  ? l.settlementIsOwed
                  : balance.cents < 0
                    ? l.settlementOwes
                    : l.settlementBalanced,
                trailing: Text(amount(balance.cents.abs()),
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: balance.cents == 0
                      ? colors.onSurfaceVariant : colors.primary,
                  )),
              ),
              const SizedBox(height: 10),
            ],
            const SizedBox(height: 20),
            Text(l.repaymentLimitations,
              style: Theme.of(context).textTheme.bodySmall),
          ],
        ],
      ),
    );
  }
}


class RepaymentReceiptForm extends StatefulWidget {
  const RepaymentReceiptForm({
    super.key, required this.groupId, required this.currency,
    required this.senderName, required this.receiverName,
    required this.fromUserId, required this.toUserId,
    required this.maxCents,
  });
  final String groupId, currency, senderName, receiverName;
  final String fromUserId, toUserId;
  final int maxCents;
  @override State<RepaymentReceiptForm> createState() => _RepaymentReceiptFormState();
}

class _RepaymentReceiptFormState extends State<RepaymentReceiptForm> {
  final formKey = GlobalKey<FormState>();
  final amount = TextEditingController();
  final note = TextEditingController();
  bool saving = false;

  @override void initState() {
    super.initState();
    amount.text = (widget.maxCents / 100).toStringAsFixed(2);
  }

  @override void dispose() {
    amount.dispose();
    note.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (saving || !(formKey.currentState?.validate() ?? false)) return;
    setState(() => saving = true);
    try {
      await Supabase.instance.client.rpc('record_trip_repayment', params: {
        'p_group': widget.groupId,
        'p_from': widget.fromUserId,
        'p_to': widget.toUserId,
        'p_amount': double.parse(amount.text.trim()),
        'p_note': note.text.trim(),
      });
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l.repaymentConfirmReceived)),
      body: Form(key: formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            Text(widget.senderName + ' → ' + widget.receiverName,
              style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 14),
            Text(l.repaymentConfirmWarning,
              style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 22),
            LuiFormLabel(l.expenseAmount),
            TextFormField(
              controller: amount,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(prefixText: widget.currency + ' '),
              validator: (raw) {
                final value = (raw ?? '').trim();
                final parsed = double.tryParse(value);
                if (!RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(value) ||
                    parsed == null || !parsed.isFinite || parsed <= 0 ||
                    parsed > widget.maxCents / 100) return l.invalid;
                return null;
              },
            ),
            const SizedBox(height: 22),
            LuiFormLabel(l.repaymentNote),
            TextFormField(
              controller: note, maxLength: 120,
              decoration: InputDecoration(hintText: l.repaymentNoteHint),
            ),
            const SizedBox(height: 25),
            FilledButton.icon(
              onPressed: saving ? null : save,
              icon: const Icon(Icons.verified_outlined),
              label: Text(l.repaymentConfirmReceived),
            ),
          ],
        ),
      ),
    );
  }
}
