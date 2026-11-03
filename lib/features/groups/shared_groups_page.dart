import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../main.dart' show CreateGroup, Group;

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

  Future<void> join(String code, String nickname) async {
    await auth();
    await db.rpc('join_trip_group', params: {
      'p_token': code.trim().toLowerCase(), 'p_nickname': nickname,
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
  const SharedGroupsPage({super.key});
  @override State<SharedGroupsPage> createState() => _SharedGroupsPageState();
}

class _SharedGroupsPageState extends State<SharedGroupsPage> {
  final api = SharedGroupApi();
  List<Map<String, dynamic>> groups = [];
  bool busy = true;
  String? error;
  String nickname = '';

  @override void initState() { super.initState(); refresh(); }

  Future<void> refresh() async {
    setState(() { busy = true; error = null; });
    try {
      final prefs = await SharedPreferences.getInstance();
      nickname = prefs.getString('shared_nickname') ?? '';
      final result = await api.groups();
      if (mounted) setState(() => groups = result);
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<String?> askText(String title, String hint, {String initial = ''}) async {
    final controller = TextEditingController(text: initial);
    final l = AppLocalizations.of(context)!;
    final result = await showDialog<String>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: Text(title),
        content: TextField(controller: controller, maxLength: 80,
          decoration: InputDecoration(hintText: hint)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialog),
            child: Text(l.cloudCancel)),
          FilledButton(onPressed: () {
            if (controller.text.trim().isNotEmpty) {
              Navigator.pop(dialog, controller.text.trim());
            }
          }, child: Text(l.cloudContinue)),
        ],
      ),
    );
    controller.dispose();
    return result;
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
    if (code != null) await execute(() => api.join(code, name));
  }

  @override Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l.cloudGroups), actions: [
        IconButton(onPressed: busy ? null : refresh, icon: const Icon(Icons.refresh),
          tooltip: l.cloudRefresh),
      ]),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        Container(padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFFFF808C), Color(0xFFFFC37A)]),
            borderRadius: BorderRadius.circular(28)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('👯 ✈️ 🎉', style: TextStyle(fontSize: 38)),
            const SizedBox(height: 12),
            Text(l.cloudTitle, style: const TextStyle(
              color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            Text(l.cloudSubtitle, style: const TextStyle(color: Colors.white)),
          ]),
        ),
        const SizedBox(height: 18),
        Row(children: [
          Expanded(child: FilledButton.icon(onPressed: busy ? null : create,
            icon: const Icon(Icons.add), label: Text(l.newGroup))),
          const SizedBox(width: 10),
          Expanded(child: OutlinedButton.icon(onPressed: busy ? null : join,
            icon: const Icon(Icons.group_add), label: Text(l.cloudJoin))),
        ]),
        const SizedBox(height: 18),
        if (busy) const Center(child: CircularProgressIndicator()),
        if (error != null) Text(error!,
          style: TextStyle(color: Theme.of(context).colorScheme.error)),
        if (!busy && error == null && groups.isEmpty)
          Card(child: Padding(padding: const EdgeInsets.all(22),
            child: Text(l.cloudEmpty))),
        for (final g in groups) Card(child: ListTile(
          contentPadding: const EdgeInsets.all(18),
          leading: Text(g['is_travel'] == true ? '🌴' : '🍕',
            style: const TextStyle(fontSize: 30)),
          title: Text(g['name'] as String,
            style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text((g['spending_currency'] as String) + ' • ' +
            (g['settlement_currency'] as String)),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.push(context, MaterialPageRoute(
            builder: (_) => SharedGroupDetail(api: api, group: g))),
        )),
        const SizedBox(height: 20),
        Text(l.cloudIdentityWarning, style: Theme.of(context).textTheme.bodySmall),
      ]),
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
  bool busy = true;
  String? error, invite;
  List<Map<String, dynamic>> members = [];

  @override void initState() { super.initState(); refresh(); }

  Future<void> refresh() async {
    setState(() { busy = true; error = null; });
    try {
      final id = widget.group['id'] as String;
      final data = await widget.api.members(id);
      final token = await widget.api.invite(id);
      if (mounted) setState(() { members = data; invite = token; });
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> resetCode() async {
    try {
      final token = await widget.api.rotate(widget.group['id'] as String);
      if (mounted) setState(() => invite = token);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())));
    }
  }

  @override Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final uid = Supabase.instance.client.auth.currentUser?.id;
    final owner = members.any((m) => m['user_id'] == uid && m['role'] == 'owner');
    return Scaffold(
      appBar: AppBar(title: Text(widget.group['name'] as String),
        actions: [IconButton(onPressed: refresh, icon: const Icon(Icons.refresh),
          tooltip: l.cloudRefresh)]),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        const Center(child: Text('🌈 🧳', style: TextStyle(fontSize: 48))),
        const SizedBox(height: 16),
        if (busy) const Center(child: CircularProgressIndicator()),
        if (error != null) Text(error!),
        if (invite != null) Card(child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(l.cloudInviteCode, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            SelectableText(invite!, style: const TextStyle(fontFamily: 'monospace')),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: invite!));
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l.cloudCopied)));
              },
              icon: const Icon(Icons.copy), label: Text(l.cloudCopyInvite)),
            if (owner) TextButton.icon(
              onPressed: resetCode, icon: const Icon(Icons.lock_reset),
              label: Text(l.cloudResetInvite)),
          ]),
        )),
        const SizedBox(height: 20),
        Text(l.members, style: Theme.of(context).textTheme.titleLarge),
        for (final m in members) Card(child: ListTile(
          leading: const CircleAvatar(child: Icon(Icons.person)),
          title: Text(m['nickname'] as String),
          trailing: m['role'] == 'owner' ? Text(l.cloudOwner) : null,
        )),
        const SizedBox(height: 20),
        Text(l.cloudExpenseNext, style: Theme.of(context).textTheme.bodySmall),
      ]),
    );
  }
}
