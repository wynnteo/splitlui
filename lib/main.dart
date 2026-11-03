import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'features/groups/shared_groups_page.dart';
import 'l10n/generated/app_localizations.dart';

const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
const cloudEnabled = supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (cloudEnabled) {
    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  }
  runApp(const SplitLui());
}

class Group {
  Group(this.id, this.name, this.travel, this.spending, this.settlement, this.rate, this.budget);
  final String id, name, spending, settlement;
  final bool travel;
  final double rate;
  final double? budget;
  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'travel': travel, 'spending': spending,
    'settlement': settlement, 'rate': rate, 'budget': budget
  };
  factory Group.fromJson(Map<String, dynamic> x) => Group(
    x['id'] as String, x['name'] as String, x['travel'] as bool,
    x['spending'] as String, x['settlement'] as String,
    (x['rate'] as num).toDouble(), (x['budget'] as num?)?.toDouble(),
  );
}

class SplitLui extends StatefulWidget {
  const SplitLui({super.key});
  @override State<SplitLui> createState() => _SplitLuiState();
}

class _SplitLuiState extends State<SplitLui> {
  String language = 'en';
  ThemeMode mode = ThemeMode.system;
  List<Group> groups = [];
  bool loaded = false;
  AppLocalizations? _l10n;
  String t(String key) {
    final l = _l10n;
    if (l == null) return key;
    return switch (key) {
      'hello' => l.hello,
      'subtitle' => l.subtitle,
      'groups' => l.groups,
      'new' => l.newGroup,
      'empty' => l.empty,
      'settings' => l.settings,
      'theme' => l.theme,
      'language' => l.language,
      'system' => l.system,
      'light' => l.light,
      'dark' => l.dark,
      'name' => l.name,
      'travel' => l.travel,
      'hangout' => l.hangout,
      'spending' => l.spending,
      'settlement' => l.settlement,
      'rate' => l.rate,
      'budget' => l.budget,
      'create' => l.create,
      'required' => l.required,
      'invalid' => l.invalid,
      'expenses' => l.expenses,
      'fund' => l.fund,
      'members' => l.members,
      'soon' => l.soon,
      'local' => l.local,
      _ => key,
    };
  }

  @override
  void initState() { super.initState(); load(); }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    var saved = <Group>[];
    try {
      final raw = prefs.getString('groups_v1');
      if (raw != null) {
        saved = (jsonDecode(raw) as List).map((e) =>
          Group.fromJson(Map<String, dynamic>.from(e as Map))).toList();
      }
    } catch (_) { /* Keep saved data untouched if invalid. */ }
    if (!mounted) return;
    setState(() {
      language = prefs.getString('language') ?? 'en';
      if (language != 'en' && language != 'zh') language = 'en';
      mode = ThemeMode.values.firstWhere((e) => e.name == prefs.getString('theme'),
        orElse: () => ThemeMode.system);
      groups = saved;
      loaded = true;
    });
  }

  Future<void> setLanguage(String value) async {
    setState(() => language = value);
    (await SharedPreferences.getInstance()).setString('language', value);
  }
  Future<void> setMode(ThemeMode value) async {
    setState(() => mode = value);
    (await SharedPreferences.getInstance()).setString('theme', value.name);
  }
  Future<void> addGroup(BuildContext context) async {
    final result = await Navigator.push<Group>(context,
      MaterialPageRoute(builder: (_) => CreateGroup(t: t)));
    if (result == null) return;
    final updated = [...groups, result];
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('groups_v1', jsonEncode(updated.map((e) => e.toJson()).toList()));
    if (!mounted) return;
    setState(() => groups = updated);
  }

  ThemeData design(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFFFF717A), brightness: brightness,
      surface: dark ? const Color(0xFF252432) : const Color(0xFFFFFDFB));
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: dark ? const Color(0xFF171621) : const Color(0xFFFFF6F0),
      appBarTheme: const AppBarTheme(backgroundColor: Colors.transparent),
      cardTheme: CardThemeData(elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))),
      inputDecorationTheme: InputDecorationTheme(filled: true,
        border: OutlineInputBorder(borderSide: BorderSide.none,
          borderRadius: BorderRadius.circular(18))),
    );
  }

  @override Widget build(BuildContext context) => MaterialApp(
    onGenerateTitle: (context) { _l10n = AppLocalizations.of(context)!; return 'SplitLui'; },
    debugShowCheckedModeBanner: false,
    theme: design(Brightness.light), darkTheme: design(Brightness.dark), themeMode: mode,
    locale: Locale(language),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: Builder(builder: (context) => Scaffold(
      appBar: AppBar(
        title: const Text('SplitLui 🌈', style: TextStyle(fontWeight: FontWeight.w900)),
        actions: [IconButton(
          tooltip: t('settings'), icon: const Icon(Icons.tune_rounded),
          onPressed: () => Navigator.push(context, MaterialPageRoute(
            builder: (_) => Settings(t: t, language: language, mode: mode,
              onLanguage: setLanguage, onMode: setMode))),
        )],
      ),
      body: !loaded ? const Center(child: CircularProgressIndicator()) : ListView(
        padding: const EdgeInsets.all(20), children: [
          Container(padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(30),
              gradient: const LinearGradient(colors: [Color(0xFFFF797F), Color(0xFFFFB676)])),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('🧳 ✈️ 🍜', style: TextStyle(fontSize: 34)),
              const SizedBox(height: 20),
              Text(t('hello'), style: const TextStyle(color: Colors.white,
                fontSize: 27, fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              Text(t('subtitle'), style: const TextStyle(color: Colors.white)),
            ]),
          ),
          const SizedBox(height: 18),
          Card(child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(AppLocalizations.of(context)!.cloudTitle,
                style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 6),
              Text(AppLocalizations.of(context)!.cloudSubtitle),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: cloudEnabled ? () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const SharedGroupsPage())) : null,
                icon: const Icon(Icons.group_add_outlined),
                label: Text(AppLocalizations.of(context)!.cloudGroups),
              ),
              if (!cloudEnabled) Text(AppLocalizations.of(context)!.cloudNotConfigured,
                style: Theme.of(context).textTheme.bodySmall),
            ]),
          )),
          const SizedBox(height: 24),
          Row(children: [
            Expanded(child: Text(t('groups'),
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800))),
            IconButton.filledTonal(onPressed: () => addGroup(context),
              icon: const Icon(Icons.add_rounded)),
          ]),
          const SizedBox(height: 8),
          if (groups.isEmpty) Card(child: Padding(padding: const EdgeInsets.all(28),
            child: Column(children: [
              const Text('🎒', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 12), Text(t('empty'), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton.icon(onPressed: () => addGroup(context),
                icon: const Icon(Icons.add), label: Text(t('new'))),
            ]))),
          for (final group in groups) Card(child: ListTile(
            contentPadding: const EdgeInsets.all(18),
            leading: Text(group.travel ? '🌴' : '🍕', style: const TextStyle(fontSize: 30)),
            title: Text(group.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(group.spending + ' • ' + group.settlement),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => GroupPage(group: group, t: t))),
          )),
          const SizedBox(height: 16),
          Text(t('local'), textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    )),
  );
}

class CreateGroup extends StatefulWidget {
  const CreateGroup({super.key, required this.t});
  final String Function(String) t;
  @override State<CreateGroup> createState() => _CreateGroupState();
}
class _CreateGroupState extends State<CreateGroup> {
  static const currencies = ['SGD','JPY','MYR','THB','USD','EUR','GBP','KRW','TWD','IDR','CNY','AUD'];
  final form = GlobalKey<FormState>();
  final name = TextEditingController(), rate = TextEditingController(text: '115'),
      budget = TextEditingController();
  bool travel = true;
  String spending = 'JPY', settlement = 'SGD';

  @override void dispose() {
    name.dispose(); rate.dispose(); budget.dispose(); super.dispose();
  }
  @override Widget build(BuildContext context) {
    final t = widget.t;
    return Scaffold(
      appBar: AppBar(title: Text(t('new'))),
      body: Form(key: form, child: ListView(padding: const EdgeInsets.all(20), children: [
        const Center(child: Text('🧳 🎉', style: TextStyle(fontSize: 56))),
        const SizedBox(height: 16),
        SegmentedButton<bool>(
          segments: [ButtonSegment(value: true, label: Text(t('travel'))),
            ButtonSegment(value: false, label: Text(t('hangout')))],
          selected: {travel}, onSelectionChanged: (v) => setState(() => travel = v.first)),
        const SizedBox(height: 18),
        TextFormField(controller: name, decoration: InputDecoration(labelText: t('name')),
          validator: (v) => (v ?? '').trim().isEmpty ? t('required') : null),
        const SizedBox(height: 14),
        DropdownButtonFormField<String>(value: spending,
          decoration: InputDecoration(labelText: t('spending')),
          items: currencies.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
          onChanged: (v) { if (v != null) setState(() {
            spending = v;
            if (spending == settlement) rate.text = '1';
          }); }),
        const SizedBox(height: 14),
        DropdownButtonFormField<String>(value: settlement,
          decoration: InputDecoration(labelText: t('settlement')),
          items: currencies.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
          onChanged: (v) { if (v != null) setState(() {
            settlement = v;
            if (spending == settlement) rate.text = '1';
          }); }),
        const SizedBox(height: 14),
        TextFormField(controller: rate,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(labelText: t('rate'),
            helperText: AppLocalizations.of(context)!.rateHint),
          validator: (v) {
            final n = double.tryParse(v ?? '');
            return n == null || !n.isFinite || n <= 0 ? t('invalid') : null;
          }),
        const SizedBox(height: 14),
        TextFormField(controller: budget,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(labelText: t('budget')),
          validator: (v) {
            if ((v ?? '').trim().isEmpty) return null;
            final n = double.tryParse(v!);
            return n == null || !n.isFinite || n < 0 ? t('invalid') : null;
          }),
        const SizedBox(height: 24),
        FilledButton(onPressed: () {
          if (!form.currentState!.validate()) return;
          Navigator.pop(context, Group(
            DateTime.now().microsecondsSinceEpoch.toString(), name.text.trim(),
            travel, spending, settlement, double.parse(rate.text),
            budget.text.trim().isEmpty ? null : double.parse(budget.text)));
        }, child: Text(t('create'))),
      ])),
    );
  }
}

class GroupPage extends StatelessWidget {
  const GroupPage({super.key, required this.group, required this.t});
  final Group group;
  final String Function(String) t;
  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(group.name)),
    body: ListView(padding: const EdgeInsets.all(20), children: [
      Card(child: Padding(padding: const EdgeInsets.all(24), child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(group.travel ? '✈️ 🌸' : '🍕 🎉',
            style: const TextStyle(fontSize: 38)),
          const SizedBox(height: 10),
          Text(group.name, style: const TextStyle(fontSize: 25,
            fontWeight: FontWeight.w900)),
          Text('1 ' + group.settlement + ' = ' +
            group.rate.toString() + ' ' + group.spending),
          if (group.budget != null) Text(t('budget') + ': ' +
            group.budget.toString() + ' ' + group.spending),
        ]))),
      for (final item in [
        ['💸', t('expenses')], ['🪙', t('fund')], ['👯', t('members')]
      ]) Card(child: ListTile(
        contentPadding: const EdgeInsets.all(18),
        leading: Text(item[0], style: const TextStyle(fontSize: 30)),
        title: Text(item[1]),
        subtitle: Text(t('soon')),
      )),
      const SizedBox(height: 14),
      Text(t('local'), style: Theme.of(context).textTheme.bodySmall),
    ]),
  );
}

class Settings extends StatelessWidget {
  const Settings({super.key, required this.t, required this.mode,
    required this.language, required this.onMode, required this.onLanguage});
  final String Function(String) t;
  final ThemeMode mode;
  final String language;
  final ValueChanged<ThemeMode> onMode;
  final ValueChanged<String> onLanguage;

  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(t('settings'))),
    body: ListView(padding: const EdgeInsets.all(20), children: [
      Text(t('theme'), style: Theme.of(context).textTheme.titleLarge),
      for (final choice in ThemeMode.values) ListTile(
        title: Text(t(choice.name)),
        trailing: mode == choice ? const Icon(Icons.check_circle) : null,
        onTap: () => onMode(choice),
      ),
      const Divider(),
      Text(t('language'), style: Theme.of(context).textTheme.titleLarge),
      for (final item in const {
        'en':'English', 'zh':'简体中文'
      }.entries) ListTile(
        title: Text(item.value),
        trailing: language == item.key ? const Icon(Icons.check_circle) : null,
        onTap: () => onLanguage(item.key),
      ),
      const SizedBox(height: 24),
      Text(AppLocalizations.of(context)!.version, textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodySmall),
    ]),
  );
}
