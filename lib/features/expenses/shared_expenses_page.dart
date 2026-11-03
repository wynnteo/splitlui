import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../ui/lui_style.dart';

class SharedExpenseApi {
  final SupabaseClient db = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> list(String groupId) async {
    final rows = await db.from('trip_expenses')
        .select('id,title,amount,currency,rate_to_spending,amount_spending,paid_by,created_at')
        .eq('group_id', groupId).order('created_at', ascending: false);
    return (rows as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<Map<String,dynamic>?> fundBalance(String groupId) async {
    return await db.from('trip_fund_accounts')
        .select('balance').eq('group_id', groupId).maybeSingle();
  }

  Future<List<Map<String,dynamic>>> fundPurchases(String groupId) async {
    final rows = await db.from('trip_fund_entries')
        .select('id,description,amount,original_amount,original_currency,rate_to_spending,created_at')
        .eq('group_id', groupId).eq('entry_type','expense')
        .order('created_at',ascending:false);
    return rows.map((r) => Map<String,dynamic>.from(r)).toList();
  }

  Future<void> addFundPurchase({
    required String groupId, required String title,
    required double amount, required String currency,
    required double rateToSpending,
  }) async {
    await db.rpc('record_trip_fund_purchase',params: {
      'p_group':groupId, 'p_title':title.trim(), 'p_amount':amount,
      'p_currency':currency, 'p_rate_to_spending':rateToSpending,
    });
  }

  Future<void> add({
    required String groupId, required String title,
    required double amount, required String currency,
    required double rateToSpending, required String paidBy,
    required List<String> splitBetween,
  }) async {
    await db.rpc('add_trip_expense_v2', params: {
      'p_group': groupId, 'p_title': title.trim(), 'p_amount': amount,
      'p_currency': currency, 'p_rate_to_spending': rateToSpending,
      'p_paid_by': paidBy, 'p_split_between': splitBetween,
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

class _SharedExpensesPageState extends State<SharedExpensesPage> {
  final api = SharedExpenseApi();
  List<Map<String, dynamic>> expenses = [];
  List<Map<String,dynamic>> fundPurchases = [];
  bool busy = true;
  String? error;

  @override void initState() { super.initState(); refresh(); }

  String memberName(String? id) {
    for (final m in widget.members) {
      if (m['user_id'] == id) return m['nickname'] as String? ?? '';
    }
    return id ?? '';
  }

  Future<void> refresh() async {
    setState(() { busy = true; error = null; });
    try {
      final result = await Future.wait([
        api.list(widget.groupId),
        api.fundPurchases(widget.groupId),
      ]);
      if (mounted) setState(() {
        expenses = result[0];
        fundPurchases = result[1];
      });
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
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

  Future<void> showShares(Map<String, dynamic> expense) async {
    final l = AppLocalizations.of(context)!;
    await showModalBottomSheet<void>(
      context: context, isScrollControlled: true, showDragHandle: true,
      builder: (_) => FutureBuilder<List<Map<String, dynamic>>>(
        future: api.shares(expense['id'] as String),
        builder: (context, snapshot) => SafeArea(child: Padding(
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
        )),
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
          Text(widget.groupName,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(widget.currency, style: TextStyle(color: scheme.onSurfaceVariant)),
          const SizedBox(height: 22),
          FilledButton.icon(
            onPressed: widget.members.isEmpty || busy ? null : createExpense,
            icon: const Icon(Icons.add_rounded), label: Text(l.addExpense)),
          const SizedBox(height: 24),
          if (busy) const Center(child: CircularProgressIndicator()),
          if (error != null) Text(error!, style: TextStyle(color: scheme.error)),
          if (!busy && error == null &&
              expenses.isEmpty && fundPurchases.isEmpty)
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
              onTap: () => showShares(expense),
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
  });
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

  @override void initState() {
    super.initState();
    expenseCurrency = widget.currency;
    exchangeRate.text = '1';
    final ownId = Supabase.instance.client.auth.currentUser?.id;
    payer = widget.members.any((m) => m['user_id'] == ownId)
      ? ownId : (widget.members.isEmpty ? null :
          widget.members.first['user_id'] as String);
    selected.addAll(widget.members.map((m) => m['user_id'] as String));
    loadFund();
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
    if (saving || !(form.currentState?.validate() ?? false)) return;
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
      if (payFromFund) {
        await widget.api.addFundPurchase(
          groupId: widget.groupId,
          title: title.text,
          amount: double.parse(amount.text.trim()),
          currency: expenseCurrency,
          rateToSpending: expenseCurrency == widget.currency
              ? 1 : double.parse(exchangeRate.text.trim()),
        );
      } else {
      await widget.api.add(
        groupId: widget.groupId, title: title.text,
        amount: double.parse(amount.text.trim()),
        currency: expenseCurrency,
        rateToSpending: expenseCurrency == widget.currency
          ? 1 : double.parse(exchangeRate.text.trim()),
        paidBy: payer!,
        splitBetween: widget.members.map((m) => m['user_id'] as String)
          .where(selected.contains).toList(),
      );
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
      appBar: AppBar(title: Text(l.addExpense)),
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
          const SizedBox(height: 22),
          LuiFormLabel(l.paidBy),
          if (!fundLoading && (fundAvailable ?? 0) > 0) ...[
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
            onPressed: saving ? null : save,
            child: saving
              ? const SizedBox(height: 20, width: 20,
                child: CircularProgressIndicator(strokeWidth: 2))
              : Text(l.saveExpense),
          ),
        ]),
      )),
    );
  }
}
