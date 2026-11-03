import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SplitLui());
}

const translations = <String, Map<String, String>>{
  'en': {
    'hello': 'Good times. Fair shares!', 'subtitle': 'Make memories, not money drama.',
    'groups': 'Your groups', 'new': 'Create group', 'empty': 'Your next adventure starts here!',
    'settings': 'Settings', 'theme': 'Appearance', 'language': 'Language',
    'system': 'System', 'light': 'Light', 'dark': 'Dark',
    'name': 'Group name', 'travel': 'Travel', 'hangout': 'Hangout',
    'spending': 'Spending currency', 'settlement': 'Settlement currency',
    'rate': 'Spending currency per 1 settlement currency',
    'budget': 'Budget (optional, spending currency)', 'create': 'Create group',
    'required': 'Please enter a group name', 'invalid': 'Please enter a valid number',
    'expenses': 'Expenses', 'fund': 'Common fund', 'members': 'Members',
    'soon': 'Coming in the next feature!',
    'local': 'Saved on this device. Group invitations and sync are not available yet.',
  },
  'zh': {
    'hello': '一起玩，轻松分账！', 'subtitle': '开心出游，不为钱烦恼。',
    'groups': '我的群组', 'new': '创建群组', 'empty': '下一趟旅程从这里开始！',
    'settings': '设置', 'theme': '外观', 'language': '语言',
    'system': '跟随系统', 'light': '浅色', 'dark': '深色',
    'name': '群组名称', 'travel': '旅行', 'hangout': '聚会',
    'spending': '消费货币', 'settlement': '结算货币',
    'rate': '每 1 单位结算货币可兑换多少消费货币',
    'budget': '预算（选填，以消费货币计）', 'create': '创建群组',
    'required': '请输入群组名称', 'invalid': '请输入有效数字',
    'expenses': '开销', 'fund': '共同基金', 'members': '成员',
    'soon': '下一个阶段推出！',
    'local': '目前只保存在这台设备，邀请和实时同步尚未开放。',
  },
  'ms': {
    'hello': 'Seronok bersama, kongsi adil!', 'subtitle': 'Cipta kenangan, bukan drama duit.',
    'groups': 'Kumpulan anda', 'new': 'Cipta kumpulan', 'empty': 'Pengembaraan bermula di sini!',
    'settings': 'Tetapan', 'theme': 'Paparan', 'language': 'Bahasa',
    'system': 'Sistem', 'light': 'Cerah', 'dark': 'Gelap',
    'name': 'Nama kumpulan', 'travel': 'Percutian', 'hangout': 'Lepak',
    'spending': 'Mata wang belanja', 'settlement': 'Mata wang penyelesaian',
    'rate': 'Mata wang belanja bagi 1 unit penyelesaian',
    'budget': 'Bajet (pilihan)', 'create': 'Cipta kumpulan',
    'required': 'Masukkan nama kumpulan', 'invalid': 'Masukkan nombor yang sah',
    'expenses': 'Perbelanjaan', 'fund': 'Dana bersama', 'members': 'Ahli',
    'soon': 'Akan datang!',
    'local': 'Disimpan pada peranti ini sahaja. Jemputan dan sync belum tersedia.',
  },
  'ja': {
    'hello': '楽しく旅して、気軽に割り勘！', 'subtitle': 'お金より思い出を。',
    'groups': 'グループ', 'new': 'グループを作成', 'empty': '次の旅はここから！',
    'settings': '設定', 'theme': 'テーマ', 'language': '言語',
    'system': 'システム', 'light': 'ライト', 'dark': 'ダーク',
    'name': 'グループ名', 'travel': '旅行', 'hangout': 'お出かけ',
    'spending': '支出通貨', 'settlement': '精算通貨',
    'rate': '精算通貨1単位あたりの支出通貨',
    'budget': '予算（任意）', 'create': '作成',
    'required': 'グループ名を入力', 'invalid': '有効な数値を入力',
    'expenses': '支出', 'fund': '共有資金', 'members': 'メンバー',
    'soon': '次の更新で追加！',
    'local': 'この端末にのみ保存されます。招待と同期は未対応です。',
  },
};

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
  String t(String key) => translations[language]?[key] ?? translations['en']![key] ?? key;

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
      if (!translations.containsKey(language)) language = 'en';
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
    title: 'SplitLui', debugShowCheckedModeBanner: false,
    theme: design(Brightness.light), darkTheme: design(Brightness.dark), themeMode: mode,
    locale: Locale(language),
    supportedLocales: const [Locale('en'), Locale('zh'), Locale('ms'), Locale('ja')],
    localizationsDelegates: const [
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
            helperText: 'Example: 1 SGD = 115 JPY → 115'),
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
        'en':'English', 'zh':'简体中文', 'ms':'Bahasa Melayu', 'ja':'日本語'
      }.entries) ListTile(
        title: Text(item.value),
        trailing: language == item.key ? const Icon(Icons.check_circle) : null,
        onTap: () => onLanguage(item.key),
      ),
      const SizedBox(height: 24),
      Text('SplitLui 0.1.0 🌈', textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodySmall),
    ]),
  );
}
