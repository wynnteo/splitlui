import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../ui/lui_style.dart';

/// V1: a manual ledger, not a payment processor. A contribution records money
/// physically received; a fund expense reduces pooled money and is not split.
class CommonFundApi {
  final db = Supabase.instance.client;

  Future<Map<String, dynamic>?> account(String groupId) async {
    final data = await db.from('trip_fund_accounts')
        .select('balance,low_balance_threshold')
        .eq('group_id', groupId).maybeSingle();
    return data;
  }

  Future<List<Map<String, dynamic>>> entries(String groupId) async {
    final data = await db.from('trip_fund_entries')
        .select('id,entry_type,amount,member_id,description,recorded_by,created_at')
        .eq('group_id', groupId).order('created_at', ascending: false);
    return (data as List)
        .map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }

  Future<void> record({
    required String groupId, required bool contribution,
    required String description, required double amount, String? contributor,
  }) async {
    await db.rpc('record_trip_fund_entry', params: {
      'p_group': groupId,
      'p_type': contribution ? 'contribution' : 'expense',
      'p_amount': amount,
      'p_member': contribution ? contributor : null,
      'p_description': description.trim(),
    });
  }

  Future<void> setThreshold(String groupId, double threshold) async {
    await db.rpc('set_trip_fund_threshold', params: {
      'p_group': groupId, 'p_threshold': threshold,
    });
  }
}

class CommonFundPage extends StatefulWidget {
  const CommonFundPage({
    super.key, required this.groupId, required this.currency,
    required this.groupName, required this.members,
  });

  final String groupId, currency, groupName;
  final List<Map<String, dynamic>> members;

  @override State<CommonFundPage> createState() => _CommonFundPageState();
}

class _CommonFundPageState extends State<CommonFundPage> {
  final api = CommonFundApi();
  Map<String, dynamic>? account;
  List<Map<String, dynamic>> entries = [];
  bool busy = true;
  String? error;

  String nameOf(String? memberId) {
    for (final member in widget.members) {
      if (member['user_id'] == memberId) {
        return member['nickname'] as String? ?? '';
      }
    }
    return memberId ?? '';
  }

  bool get isOwner {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    return widget.members.any(
      (m) => m['user_id'] == uid && m['role'] == 'owner');
  }

  @override void initState() {
    super.initState();
    refresh();
  }

  Future<void> refresh() async {
    if (mounted) setState(() { busy = true; error = null; });
    try {
      final results = await Future.wait<Object?>([
        api.account(widget.groupId),
        api.entries(widget.groupId),
      ]);
      if (!mounted) return;
      setState(() {
        account = results[0] as Map<String, dynamic>?;
        entries = results[1] as List<Map<String, dynamic>>;
      });
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> addEntry(bool contribution) async {
    final saved = await Navigator.push<bool>(context, MaterialPageRoute(
      builder: (_) => FundEntryForm(
        api: api,
        groupId: widget.groupId,
        currency: widget.currency,
        members: widget.members,
        contribution: contribution,
      ),
    ));
    if (mounted && saved == true) await refresh();
  }

  Future<void> editThreshold() async {
    final current =
        (account?['low_balance_threshold'] as num?)?.toDouble() ?? 0;
    final value = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (_) => _FundThresholdSheet(
        initial: current.toStringAsFixed(2),
        currency: widget.currency,
      ),
    );
    if (value == null) return;
    try {
      await api.setThreshold(widget.groupId, double.parse(value));
      if (mounted) await refresh();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())));
    }
  }

  @override Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    final balance = (account?['balance'] as num?)?.toDouble() ?? 0;
    final threshold =
        (account?['low_balance_threshold'] as num?)?.toDouble() ?? 0;
    final low = threshold > 0 && balance <= threshold;

    return Scaffold(
      appBar: AppBar(
        title: Text(l.fund),
        actions: [
          IconButton(
            onPressed: busy ? null : refresh,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: l.cloudRefresh),
        ],
      ),
      body: SafeArea(top: false, child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        children: [
          Text(widget.groupName,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          Card(child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(l.fundBalance,
                style: TextStyle(color: colors.onSurfaceVariant)),
              const SizedBox(height: 10),
              Text(widget.currency + ' ' + balance.toStringAsFixed(2),
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700)),
              if (low) ...[
                const SizedBox(height: 14),
                Row(children: [
                  Icon(Icons.warning_amber_rounded,
                    color: colors.error, size: 20),
                  const SizedBox(width: 8),
                  Expanded(child: Text(l.fundLowBalance,
                    style: TextStyle(color: colors.error))),
                ]),
              ],
              if (isOwner) ...[
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: busy ? null : editThreshold,
                  icon: const Icon(Icons.tune_rounded),
                  label: Text(l.fundThreshold),
                ),
              ],
            ]),
          )),
          const SizedBox(height: 10),
          Text(l.fundManualNotice,
            style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 22),
          FilledButton.icon(
            onPressed: busy ? null : () => addEntry(true),
            icon: const Icon(Icons.add_circle_outline),
            label: Text(l.fundAddContribution),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: busy ? null : () => addEntry(false),
            icon: const Icon(Icons.receipt_long_outlined),
            label: Text(l.fundPayExpense),
          ),
          const SizedBox(height: 28),
          LuiSectionHeading(title: l.fundHistory),
          const SizedBox(height: 12),
          if (busy) const Center(child: CircularProgressIndicator()),
          if (error != null) Text(error!,
            style: TextStyle(color: colors.error)),
          if (!busy && error == null && entries.isEmpty)
            Card(child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(l.fundNoEntries, textAlign: TextAlign.center),
            )),
          for (final entry in entries) ...[
            LuiFeatureTile(
              icon: entry['entry_type'] == 'contribution'
                ? Icons.savings_outlined : Icons.shopping_bag_outlined,
              title: entry['description'] as String,
              subtitle: entry['entry_type'] == 'contribution'
                ? l.fundContributedBy + ': ' +
                    nameOf(entry['member_id'] as String?)
                : l.fundPaidFromPool,
              trailing: Text(
                (entry['entry_type'] == 'contribution' ? '+' : '-') +
                widget.currency + ' ' +
                (entry['amount'] as num).toStringAsFixed(2),
                style: TextStyle(fontWeight: FontWeight.w700,
                  color: entry['entry_type'] == 'contribution'
                    ? colors.primary : colors.onSurface),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ],
      )),
    );
  }
}

class FundEntryForm extends StatefulWidget {
  const FundEntryForm({
    super.key, required this.api, required this.groupId,
    required this.currency, required this.members,
    required this.contribution,
  });

  final CommonFundApi api;
  final String groupId, currency;
  final bool contribution;
  final List<Map<String, dynamic>> members;

  @override State<FundEntryForm> createState() => _FundEntryFormState();
}

class _FundEntryFormState extends State<FundEntryForm> {
  final form = GlobalKey<FormState>();
  final description = TextEditingController();
  final amount = TextEditingController();
  String? contributor;
  bool saving = false;

  @override void initState() {
    super.initState();
    final myId = Supabase.instance.client.auth.currentUser?.id;
    contributor = widget.members.any((m) => m['user_id'] == myId)
      ? myId : (widget.members.isNotEmpty
        ? widget.members.first['user_id'] as String : null);
  }

  @override void dispose() {
    description.dispose();
    amount.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (saving || !(form.currentState?.validate() ?? false)) return;
    if (widget.contribution && contributor == null) return;
    setState(() => saving = true);
    try {
      await widget.api.record(
        groupId: widget.groupId,
        contribution: widget.contribution,
        description: description.text,
        amount: double.parse(amount.text.trim()),
        contributor: contributor,
      );
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
      appBar: AppBar(title: Text(widget.contribution
        ? l.fundAddContribution : l.fundPayExpense)),
      body: SafeArea(top: false, child: Form(
        key: form,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
          children: [
            LuiFormLabel(widget.contribution
              ? l.fundContributionNote : l.expenseTitle),
            TextFormField(
              controller: description,
              maxLength: 120,
              decoration: InputDecoration(hintText: widget.contribution
                ? l.fundContributionHint : l.expenseTitleHint),
              validator: (v) =>
                (v ?? '').trim().isEmpty ? l.required : null,
            ),
            const SizedBox(height: 16),
            LuiFormLabel(l.expenseAmount),
            TextFormField(
              controller: amount,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true),
              decoration: InputDecoration(prefixText: widget.currency + ' '),
              validator: (v) {
                final raw = (v ?? '').trim();
                final n = double.tryParse(raw);
                if (!RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(raw)
                    || n == null || !n.isFinite || n <= 0
                    || n > 9999999999999999) return l.invalid;
                return null;
              },
            ),
            if (widget.contribution) ...[
              const SizedBox(height: 22),
              LuiFormLabel(l.fundContributor),
              DropdownButtonFormField<String>(
                value: contributor,
                isExpanded: true,
                decoration: const InputDecoration(),
                items: widget.members.map((m) => DropdownMenuItem(
                  value: m['user_id'] as String,
                  child: Text(m['nickname'] as String))).toList(),
                onChanged: saving ? null :
                  (value) => setState(() => contributor = value),
              ),
            ],
            const SizedBox(height: 16),
            Text(widget.contribution ? l.fundRecordActual
              : l.fundNoDoubleSplit,
              style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 30),
            FilledButton(
              onPressed: saving ? null : save,
              child: saving
                ? const SizedBox(height: 20, width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : Text(l.saveExpense),
            ),
          ],
        ),
      )),
    );
  }
}


class _FundThresholdSheet extends StatefulWidget {
  const _FundThresholdSheet({required this.initial, required this.currency});
  final String initial, currency;
  @override State<_FundThresholdSheet> createState() => _FundThresholdSheetState();
}

class _FundThresholdSheetState extends State<_FundThresholdSheet> {
  late final TextEditingController value;
  final form = GlobalKey<FormState>();

  @override void initState() {
    super.initState();
    value = TextEditingController(text: widget.initial);
  }

  @override void dispose() {
    value.dispose();
    super.dispose();
  }

  @override Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: Form(key: form,
          child: Column(mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text(l.fundThreshold,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(l.fundThresholdHint,
                style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 20),
              TextFormField(
                controller: value,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true),
                decoration: InputDecoration(prefixText: widget.currency + ' '),
                validator: (text) {
                  final raw = (text ?? '').trim();
                  final n = double.tryParse(raw);
                  if (!RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(raw) ||
                      n == null || !n.isFinite || n < 0 ||
                      n > 9999999999999999) return l.invalid;
                  return null;
                },
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () {
                  if (form.currentState?.validate() == true) {
                    Navigator.pop(context,value.text.trim());
                  }
                },
                child: Text(l.saveChanges),
              ),
              const SizedBox(height: 6),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l.cloudCancel),
              ),
            ]),
        ),
      ),
    );
  }
}
