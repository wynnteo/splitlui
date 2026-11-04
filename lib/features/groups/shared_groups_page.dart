import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../main.dart' show CreateGroup, Group;
import '../expenses/shared_expenses_page.dart';
import '../expenses/offline_expense_outbox.dart';
import '../fund/common_fund_page.dart';
import '../settlement/settlement_page.dart';
import '../reports/trip_closing_report_page.dart';
import '../../ui/lui_style.dart';
import 'group_invite_message.dart';

class SharedGroupApi {
  final SupabaseClient db = Supabase.instance.client;
  Future<void> auth() async {
    if (db.auth.currentUser == null) await db.auth.signInAnonymously();
  }

  Future<List<Map<String, dynamic>>> groups() async {
    await auth();
    final myId = db.auth.currentUser!.id;
    final memberships = await db.from('trip_members')
        .select('group_id').eq('user_id', myId);
    final ids = (memberships as List).map((e) => e['group_id'] as String).toList();
    if (ids.isEmpty) return [];
    final result = await db.from('trip_groups').select()
        .inFilter('id', ids).order('created_at', ascending: false);
    return (result as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<void> create(Group g, String nickname) async {
    await auth();
    await db.rpc('create_trip_group', params: {
      'p_name': g.name, 'p_is_travel': g.travel,
      'p_spending': g.spending, 'p_settlement': g.settlement,
      'p_rate': g.rate, 'p_budget': g.budget, 'p_nickname': nickname,
    });
  }

  Future<void> updateGroup(String id, Group group) async {
    await db.rpc('update_trip_group', params: {
      'p_group': id, 'p_name': group.name,
      'p_is_travel': group.travel, 'p_rate': group.rate,
      'p_budget': group.budget,
    });
  }

  Future<void> deleteGroup(String id, String confirmation) async {
    await db.rpc('delete_trip_group', params: {
      'p_group': id, 'p_confirm_name': confirmation,
    });
  }

  Future<void> join(String code, String nickname) async {
    await auth();
    await db.rpc('join_trip_group', params: {
      'p_token': GroupInviteMessage.codeFromPaste(code) ?? code.trim().toLowerCase(), 'p_nickname': nickname,
    });
  }

  Future<List<Map<String, dynamic>>> members(String id) async {
    final data = await db.from('trip_members')
        .select('user_id,nickname,role').eq('group_id', id).order('joined_at');
    return (data as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<String> invite(String id) async =>
    (await db.rpc('get_trip_invite', params: {'p_group': id})) as String;

  Future<String> rotate(String id) async =>
    (await db.rpc('rotate_trip_invite', params: {'p_group': id})) as String;
}

class SharedGroupsPage extends StatefulWidget {
  const SharedGroupsPage({super.key, this.onSettings});
  final VoidCallback? onSettings;
  @override State<SharedGroupsPage> createState() => _SharedGroupsPageState();
}

class _SharedGroupsPageState extends State<SharedGroupsPage> {
  final api = SharedGroupApi();
  List<Map<String, dynamic>> groups = [];
  List<Group> legacyGroups = [];
  bool busy = true;
  String? error;
  String nickname = '';

  @override void initState() { super.initState(); refresh(); }

  Future<void> refresh() async {
    setState(() { busy = true; error = null; });
    try {
      final prefs = await SharedPreferences.getInstance();
      nickname = prefs.getString('shared_nickname') ?? '';
      final cache = OfflineExpenseOutbox.instance;
      try {
        final saved = await cache.cachedGroups();
        if (mounted) setState(() => groups = saved);
      } catch (_) { /* Fresh sign-ins may not have a cache yet. */ }
      final result = await api.groups();
      await cache.cacheGroups(result);
      final legacy = <Group>[];
      try {
        final raw = prefs.getString('groups_v1');
        if (raw != null) {
          for (final item in (jsonDecode(raw) as List)) {
            legacy.add(Group.fromJson(Map<String, dynamic>.from(item as Map)));
          }
        }
      } catch (_) { /* Keep malformed local backups untouched. */ }
      if (mounted) setState(() {
        groups = result;
        legacyGroups = legacy;
      });
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<String?> askText(String title, String hint, {String initial = ''}) {
    final l = AppLocalizations.of(context)!;
    return showModalBottomSheet<String>(
      context: context, isScrollControlled: true,
      useSafeArea: true, showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (_) => _SharedGroupTextDialog(
        title: title,
        hint: hint,
        initial: initial,
        cancelLabel: l.cloudCancel,
        confirmLabel: l.cloudContinue,
        maxLength: hint == l.cloudNicknameHint ? 60 : (hint == l.cloudInviteHint ? 2000 : 80),
      ),
    );
  }

  Future<String?> getNickname() async {
    final l = AppLocalizations.of(context)!;
    final name = await askText(l.cloudNickname, l.cloudNicknameHint, initial: nickname);
    if (name == null) return null;
    nickname = name;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('shared_nickname', name);
    return name;
  }

  Future<void> execute(Future<void> Function() action) async {
    setState(() => busy = true);
    try {
      await action();
      if (mounted) await refresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> create() async {
    final l = AppLocalizations.of(context)!;
    final name = await getNickname();
    if (!mounted || name == null) return;
    final group = await Navigator.push<Group>(context, MaterialPageRoute(
      builder: (_) => CreateGroup(t: (k) => {
        'new':l.newGroup, 'name':l.name, 'travel':l.travel,
        'hangout':l.hangout, 'spending':l.spending, 'settlement':l.settlement,
        'rate':l.rate, 'budget':l.budget, 'create':l.create,
        'required':l.required, 'invalid':l.invalid,
      }[k] ?? k),
    ));
    if (group != null) await execute(() => api.create(group, name));
  }

  Future<void> join() async {
    final l = AppLocalizations.of(context)!;
    final name = await getNickname();
    if (!mounted || name == null) return;
    final code = await askText(l.cloudJoin, l.cloudInviteHint);
    if (code == null) return;
    final extracted = GroupInviteMessage.codeFromPaste(code);
    if (extracted == null) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.inviteInvalidCode)));
      return;
    }
    await execute(() => api.join(extracted, name));
  }

  Future<void> migrateLegacy(Group group) async {
    final label = await getNickname();
    if (!mounted || label == null) return;
    await execute(() async {
      await api.create(group, label);
      // Delete the device-only copy only after successful cloud creation.
      final prefs = await SharedPreferences.getInstance();
      final remaining = legacyGroups.where((g) => g.id != group.id).toList();
      await prefs.setString('groups_v1',
        jsonEncode(remaining.map((g) => g.toJson()).toList()));
    });
  }

  Future<void> deleteLegacy(Group group) async {
    final l = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(context: context,
      builder: (dialog) => AlertDialog(
        title: Text(l.deleteLocalGroup),
        content: Text(l.deleteLocalWarning),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialog, false),
            child: Text(l.cloudCancel)),
          FilledButton(onPressed: () => Navigator.pop(dialog, true),
            child: Text(l.deleteGroup)),
        ],
      ));
    if (confirmed != true) return;
    final prefs = await SharedPreferences.getInstance();
    final remaining = legacyGroups.where((g) => g.id != group.id).toList();
    await prefs.setString('groups_v1',
      jsonEncode(remaining.map((g) => g.toJson()).toList()));
    if (mounted) setState(() => legacyGroups = remaining);
  }

  @override Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l.groups), actions: [
        if (widget.onSettings != null) IconButton(
          onPressed: widget.onSettings,
          tooltip: l.settings, icon: const Icon(Icons.settings_outlined)),
        IconButton(onPressed: busy ? null : refresh, icon: const Icon(Icons.refresh),
          tooltip: l.cloudRefresh),
      ]),
      body: SafeArea(top: false, child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40), children: [
        Text(l.cloudSubtitle, style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant)),
        const SizedBox(height: 24),
        Row(children:[
          Expanded(child:FilledButton.icon(
            onPressed:busy?null:create,
            icon:const Icon(Icons.add_rounded,size:20),
            label:Text(l.newGroup,textAlign:TextAlign.center))),
          const SizedBox(width:10),
          Expanded(child:OutlinedButton.icon(
            onPressed:busy?null:join,
            icon:const Icon(Icons.group_add_outlined,size:20),
            label:Text(l.cloudJoin,textAlign:TextAlign.center))),
        ]),
        const SizedBox(height: 26),
        if (busy) const Center(child: CircularProgressIndicator()),
        if (error != null) Card(child: Padding(
          padding: const EdgeInsets.all(18),
          child: Text(error!, style: TextStyle(
            color: Theme.of(context).colorScheme.error)))),
        if (!busy && error == null && groups.isEmpty && legacyGroups.isEmpty)
          Card(child: Padding(padding: const EdgeInsets.all(24),
            child: Column(children: [
              Icon(Icons.groups_2_outlined, size: 36,
                color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 12),
              Text(l.cloudEmpty, textAlign: TextAlign.center),
            ]))),
        for (final g in groups) ...[
          LuiFeatureTile(
            icon: g['is_travel'] == true
              ? Icons.flight_takeoff_outlined : Icons.restaurant_outlined,
            title: g['name'] as String,
            subtitle: (g['spending_currency'] as String) + ' / ' +
              (g['settlement_currency'] as String),
            onTap: () async {
              await Navigator.push<bool>(context,
                MaterialPageRoute(builder: (_) =>
                  SharedGroupDetail(api: api, group: g)));
              // Also reload after edits when Android's Back button is used.
              if (mounted) await refresh();
            },
          ),
          const SizedBox(height: 10),
        ],
        if (legacyGroups.isNotEmpty) ...[
          const SizedBox(height: 24),
          LuiSectionHeading(title: l.olderDeviceGroups),
          const SizedBox(height: 8),
          Text(l.olderDeviceGroupsHint,
            style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 10),
          for (final g in legacyGroups) ...[
            Card(child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(g.name, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 10),
                  Wrap(spacing: 8, children: [
                    OutlinedButton.icon(
                      onPressed: busy ? null : () => migrateLegacy(g),
                      icon: const Icon(Icons.cloud_upload_outlined),
                      label: Text(l.moveToGroups)),
                    TextButton(
                      onPressed: busy ? null : () => deleteLegacy(g),
                      child: Text(l.deleteGroup)),
                  ]),
                ]),
            )),
            const SizedBox(height: 10),
          ],
        ],
        const SizedBox(height: 20),
        Text(l.cloudIdentityWarning,
          style: Theme.of(context).textTheme.bodySmall),
      ])),
    );
  }
}

class SharedGroupDetail extends StatefulWidget {
  const SharedGroupDetail({super.key, required this.api, required this.group});
  final SharedGroupApi api;
  final Map<String, dynamic> group;
  @override State<SharedGroupDetail> createState() => _SharedGroupDetailState();
}

class _SharedGroupDetailState extends State<SharedGroupDetail> {
  late Map<String, dynamic> group;
  bool busy = true;
  String? error, invite;
  List<Map<String, dynamic>> members = [];

  @override void initState() {
    super.initState();
    group = Map<String, dynamic>.from(widget.group);
    refresh();
  }

  Future<void> refresh() async {
    setState(() { busy = true; error = null; });
    try {
      final id = group['id'] as String;
      final cache = OfflineExpenseOutbox.instance;
      try {
        final saved = await cache.cachedMembers(id);
        if (mounted && saved.isNotEmpty) {
          setState(() => members = saved);
        }
      } catch (_) { /* Cache not available for this identity. */ }
      final data = await widget.api.members(id);
      await cache.cacheMembers(id, data);
      // Invite links are deliberately NOT cached offline.
      final token = await widget.api.invite(id);
      if (mounted) setState(() { members = data; invite = token; });
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> shareInvite() async {
    if (invite == null) return;
    final l = AppLocalizations.of(context)!;
    final message = GroupInviteMessage.format(
      groupName: group['name'] as String,
      inviteCode: invite!,
      heading: l.inviteShareHeading,
      instruction: l.inviteShareInstructions,
      codeLabel: l.cloudInviteCode,
      installLabel: l.inviteInstallApp,
    );
    try {
      await SharePlus.instance.share(ShareParams(text: message));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> resetCode() async {
    try {
      final token = await widget.api.rotate(group['id'] as String);
      if (mounted) setState(() => invite = token);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> editGroup() async {
    final l = AppLocalizations.of(context)!;
    final initial = Group(
      group['id'] as String, group['name'] as String,
      group['is_travel'] as bool, group['spending_currency'] as String,
      group['settlement_currency'] as String,
      (group['exchange_rate'] as num).toDouble(),
      (group['budget'] as num?)?.toDouble(),
    );
    final updated = await Navigator.push<Group>(context, MaterialPageRoute(
      builder: (_) => CreateGroup(initial: initial, t: (key) => {
        'new':l.newGroup, 'name':l.name, 'travel':l.travel,
        'hangout':l.hangout, 'spending':l.spending,
        'settlement':l.settlement, 'rate':l.rate, 'budget':l.budget,
        'create':l.create, 'required':l.required, 'invalid':l.invalid,
      }[key] ?? key),
    ));
    if (!mounted || updated == null) return;
    setState(() => busy = true);
    try {
      await widget.api.updateGroup(group['id'] as String, updated);
      if (!mounted) return;
      setState(() {
        group['name'] = updated.name;
        group['is_travel'] = updated.travel;
        group['exchange_rate'] = updated.rate;
        group['budget'] = updated.budget;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.groupUpdated)));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> deleteGroup() async {
    final l = AppLocalizations.of(context)!;
    final confirmedName = await showModalBottomSheet<String>(
      context: context, isScrollControlled: true,
      useSafeArea: true, showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (_) => _SharedGroupTextDialog(
        title: l.deleteGroup,
        hint: l.typeGroupName + ': ' + (group['name'] as String),
        initial: '',
        cancelLabel: l.cloudCancel, confirmLabel: l.deleteGroup,
        maxLength: 120,
      ),
    );
    if (!mounted || confirmedName == null) return;
    setState(() => busy = true);
    try {
      await widget.api.deleteGroup(group['id'] as String, confirmedName);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final uid = Supabase.instance.client.auth.currentUser?.id;
    final owner = members.any((m) => m['user_id'] == uid && m['role'] == 'owner');
    return Scaffold(
      appBar: AppBar(title: Text(group['name'] as String),
        actions: [IconButton(onPressed: refresh, icon: const Icon(Icons.refresh),
          tooltip: l.cloudRefresh)]),
      body: SafeArea(top: false, child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40), children: [
        const SizedBox(height: 8),
        if (busy) const Center(child: CircularProgressIndicator()),
        if (error != null) Text(error!,
          style: TextStyle(color: Theme.of(context).colorScheme.error)),
        if (invite != null) Card(child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(l.cloudInviteCode,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            SelectableText(invite!, style: const TextStyle(
              fontFamily: 'monospace', fontSize: 12)),
            const SizedBox(height: 10),
            Text(l.inviteShareHint,
              style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 18),
            SizedBox(width: double.infinity,
              child: FilledButton.icon(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: invite!));
                  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l.cloudCopied)));
                },
                icon: const Icon(Icons.copy_outlined),
                label: Text(l.cloudCopyInvite),
              )),
            const SizedBox(height: 10),
            SizedBox(width: double.infinity,
              child: FilledButton.icon(
                onPressed: shareInvite,
                icon: const Icon(Icons.share_outlined),
                label: Text(l.inviteShareButton),
              )),
            if (owner) TextButton.icon(
              onPressed: resetCode,
              icon: const Icon(Icons.lock_reset_outlined),
              label: Text(l.cloudResetInvite)),
          ]),
        )),
        if (owner) ...[
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: OutlinedButton.icon(
              onPressed: busy || error != null ? null : editGroup,
              icon: const Icon(Icons.edit_outlined),
              label: Text(l.editGroup),
            )),
            const SizedBox(width: 10),
            OutlinedButton.icon(
              onPressed: busy || error != null ? null : deleteGroup,
              icon: const Icon(Icons.delete_outline),
              label: Text(l.deleteGroup),
            ),
          ]),
        ],
        const SizedBox(height: 24),
        LuiFeatureTile(
          icon: Icons.receipt_long_outlined,
          title: l.expenses,
          subtitle: l.expenseEntryHint,
          onTap: busy || members.isEmpty ? null : () =>
            Navigator.push(context, MaterialPageRoute(
              builder: (_) => SharedExpensesPage(
                groupId: group['id'] as String,
                groupName: group['name'] as String,
                currency: group['spending_currency'] as String,
                settlementCurrency: group['settlement_currency'] as String,
                groupRate: (group['exchange_rate'] as num).toDouble(),
                members: members,
              ),
            )),
        ),
        const SizedBox(height: 12),
        LuiFeatureTile(
          icon: Icons.account_balance_wallet_outlined,
          title: l.fund,
          subtitle: l.fundEntryHint,
          onTap: busy || error != null ? null : () =>
            Navigator.push(context, MaterialPageRoute(
              builder: (_) => CommonFundPage(
                groupId: group['id'] as String,
                groupName: group['name'] as String,
                currency: group['spending_currency'] as String,
                members: members,
              ),
            )),
        ),
        const SizedBox(height: 12),
        LuiFeatureTile(
          icon: Icons.compare_arrows_rounded,
          title: l.settlementPreview,
          subtitle: l.settlementEntryHint,
          onTap: busy || error != null ? null : () =>
            Navigator.push(context, MaterialPageRoute(
              builder: (_) => SettlementPage(
                groupId: group['id'] as String,
                groupName: group['name'] as String,
                spendingCurrency: group['spending_currency'] as String,
                settlementCurrency: group['settlement_currency'] as String,
                exchangeRate: (group['exchange_rate'] as num).toDouble(),
                members: members,
              ),
            )),
        ),
        const SizedBox(height:12),
        LuiFeatureTile(
          icon:Icons.description_outlined,
          title:l.tripReportTitle,
          subtitle:l.tripReportEntryHint,
          onTap:busy || error!=null || members.isEmpty ? null : ()=>
            Navigator.push(context,MaterialPageRoute(
              builder:(_)=>TripClosingReportPage(
                groupId:group['id'] as String,
                groupName:group['name'] as String,
                spendingCurrency:group['spending_currency'] as String,
                settlementCurrency:group['settlement_currency'] as String,
                exchangeRate:(group['exchange_rate'] as num).toDouble(),
                members:members,
              ),
            )),
        ),
        const SizedBox(height: 28),
        LuiSectionHeading(title: l.members),
        const SizedBox(height: 12),
        for (final m in members) ...[
          LuiFeatureTile(
            icon: Icons.person_outline,
            title: m['nickname'] as String,
            subtitle: m['role'] == 'owner' ? l.cloudOwner : null,
            trailing: const SizedBox.shrink(),
          ),
          const SizedBox(height: 10),
        ],
      ])),
    );
  }
}


/// A keyboard-aware, mobile-native bottom sheet for short text entry.
class _SharedGroupTextDialog extends StatefulWidget {
  const _SharedGroupTextDialog({
    required this.title, required this.hint, required this.initial,
    required this.cancelLabel, required this.confirmLabel,
    this.maxLength = 80,
  });
  final String title, hint, initial, cancelLabel, confirmLabel;
  final int maxLength;
  @override State<_SharedGroupTextDialog> createState() => _SharedGroupTextDialogState();
}

class _SharedGroupTextDialogState extends State<_SharedGroupTextDialog> {
  late final TextEditingController controller;

  @override void initState() {
    super.initState();
    controller = TextEditingController(text: widget.initial);
  }

  @override void dispose() {
    controller.dispose();
    super.dispose();
  }

  void submit() {
    final text = controller.text.trim();
    if (text.isNotEmpty) Navigator.pop(context, text);
  }

  @override Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: Column(mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(widget.title, style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(widget.hint, style: theme.textTheme.bodySmall),
            const SizedBox(height: 20),
            TextField(
              controller: controller,
              maxLength: widget.maxLength,
              autofocus: true,
              minLines: 1,
              maxLines: widget.maxLength > 100 ? 4 : 1,
              textInputAction: widget.maxLength > 100
                ? TextInputAction.newline : TextInputAction.done,
              decoration: InputDecoration(
                hintText: widget.hint,
                counterStyle: theme.textTheme.bodySmall,
              ),
              onSubmitted: (_) {
                if (widget.maxLength <= 100) submit();
              },
            ),
            const SizedBox(height: 10),
            FilledButton(
              onPressed: submit,
              child: Text(widget.confirmLabel),
            ),
            const SizedBox(height: 6),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(widget.cancelLabel),
            ),
          ]),
      ),
    );
  }
}
