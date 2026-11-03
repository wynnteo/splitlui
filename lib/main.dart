import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'features/groups/shared_groups_page.dart';
import 'features/settlement/repayment_preferences.dart';
import 'ui/lui_style.dart';
import 'l10n/generated/app_localizations.dart';

bool cloudEnabled = false;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    // This JSON contains only a public client URL and publishable key.
    // Bundled as a Flutter asset for Android Studio's standard Run button.
    final config = jsonDecode(
      await rootBundle.loadString('config/supabase.json'),
    ) as Map<String, dynamic>;
    final url = config['SUPABASE_URL'] as String? ?? '';
    final key = config['SUPABASE_ANON_KEY'] as String? ?? '';
    if (url.isNotEmpty && key.isNotEmpty) {
      await Supabase.initialize(url: url, anonKey: key);
      cloudEnabled = true;
    }
  } catch (error) {
    // Local-only features remain available if cloud configuration fails.
    debugPrint('SplitLui cloud startup unavailable: $error');
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
      'localOnlyFeatures' => l.localOnlyFeatures,
      'openSharedGroups' => l.openSharedGroups,
      'createLocalGroup' => l.createLocalGroup,
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


  @override Widget build(BuildContext context) => MaterialApp(
    onGenerateTitle: (context) { _l10n = AppLocalizations.of(context)!; return 'SplitLui'; },
    debugShowCheckedModeBanner: false,
    theme: LuiStyle.theme(Brightness.light),
    darkTheme: LuiStyle.theme(Brightness.dark), themeMode: mode,
    locale: Locale(language),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: cloudEnabled
      ? Builder(builder: (context) => SharedGroupsPage(
          onSettings: () => Navigator.push(context, MaterialPageRoute(
            builder: (_) => Settings(t: t, language: language, mode: mode,
              onLanguage: setLanguage, onMode: setMode))),
        ))
      : Builder(builder: (context) {

      final l = AppLocalizations.of(context)!;
      final colors = Theme.of(context).colorScheme;
      return Scaffold(
        appBar: AppBar(
          title: const Text('SplitLui'),
          actions: [
            IconButton(
              tooltip: l.settings,
              icon: const Icon(Icons.settings_outlined),
              onPressed: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => Settings(t: t, language: language, mode: mode,
                  onLanguage: setLanguage, onMode: setMode))),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: !loaded
          ? const Center(child: CircularProgressIndicator())
          : ListView(padding: const EdgeInsets.fromLTRB(20, 16, 20, 32), children: [
              Text(l.hello, style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700, letterSpacing: -0.8)),
              const SizedBox(height: 6),
              Text(l.subtitle, style: TextStyle(color: colors.onSurfaceVariant)),
              const SizedBox(height: 28),
              LuiFeatureTile(
                icon: Icons.groups_2_outlined,
                title: l.cloudGroups,
                subtitle: cloudEnabled ? l.cloudSubtitle : l.cloudNotConfigured,
                trailing: Icon(Icons.arrow_outward_rounded,
                  size: 20, color: colors.primary),
                onTap: cloudEnabled ? () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const SharedGroupsPage())) : null,
              ),
              const SizedBox(height: 28),
              LuiSectionHeading(
                title: l.groups,
                trailing: TextButton.icon(
                  onPressed: () => cloudEnabled
                    ? Navigator.push(context, MaterialPageRoute(
                        builder: (_) => const SharedGroupsPage()))
                    : addGroup(context),
                  icon: const Icon(Icons.add, size: 20),
                  label: Text(cloudEnabled ? l.cloudGroups : l.createLocalGroup),
                ),
              ),
              const SizedBox(height: 14),
              if (groups.isEmpty) Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 30),
                  child: Column(children: [
                    Icon(Icons.folder_open_rounded, size: 38, color: colors.primary),
                    const SizedBox(height: 12),
                    Text(l.empty, textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: () => cloudEnabled
                        ? Navigator.push(context, MaterialPageRoute(
                            builder: (_) => const SharedGroupsPage()))
                        : addGroup(context),
                      icon: const Icon(Icons.add),
                      label: Text(cloudEnabled ? l.cloudGroups : l.createLocalGroup),
                    ),
                  ]),
                ),
              ),
              for (final group in groups) ...[
                LuiFeatureTile(
                  icon: group.travel ? Icons.flight_takeoff_outlined : Icons.restaurant_outlined,
                  title: group.name,
                  subtitle: group.spending + ' / ' + group.settlement,
                  onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => GroupPage(group: group, t: t))),
                ),
                const SizedBox(height: 10),
              ],
              const SizedBox(height: 20),
              Text(l.local, style: Theme.of(context).textTheme.bodySmall),
            ]),
      );
    }),
  );
}

class CreateGroup extends StatefulWidget {
  const CreateGroup({super.key, required this.t, this.initial});
  final String Function(String) t;
  final Group? initial;
  @override State<CreateGroup> createState() => _CreateGroupState();
}
class _CreateGroupState extends State<CreateGroup> {
  static const currencies = ['SGD','JPY','MYR','THB','USD','EUR','GBP','KRW','TWD','IDR','CNY','AUD'];
  final form = GlobalKey<FormState>();
  final name = TextEditingController(), rate = TextEditingController(),
      budget = TextEditingController();
  bool travel = true;
  String spending = 'JPY', settlement = 'SGD';

  @override void initState() {
    super.initState();
    final g = widget.initial;
    if (g != null) {
      name.text = g.name;
      rate.text = g.rate.toString();
      if (g.budget != null) budget.text = g.budget.toString();
      travel = g.travel;
      spending = g.spending;
      settlement = g.settlement;
    } else {
      rate.text = '115';
    }
  }

  @override void dispose() {
    name.dispose(); rate.dispose(); budget.dispose(); super.dispose();
  }
  @override Widget build(BuildContext context) {
    final t = widget.t;
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(widget.initial == null ? t('new') : l.editGroup)),
      body: SafeArea(top: false, child: Form(
        key: form,
        child: ListView(padding: const EdgeInsets.fromLTRB(20, 12, 20, 40), children: [
          Text(widget.initial == null ? t('new') : l.editGroup, style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700, letterSpacing: -0.8)),
          const SizedBox(height: 6),
          Text(l.cloudSubtitle, style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(height: 26),
          LuiFormLabel(t('travel') + ' / ' + t('hangout')),
          SegmentedButton<bool>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(value: true, label: Text(t('travel')),
                icon: const Icon(Icons.flight_outlined, size: 18)),
              ButtonSegment(value: false, label: Text(t('hangout')),
                icon: const Icon(Icons.groups_outlined, size: 18)),
            ],
            selected: {travel},
            onSelectionChanged: (v) => setState(() => travel = v.first)),
          const SizedBox(height: 22),
          LuiFormLabel(t('name')),
          TextFormField(
            controller: name,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(hintText: l.nameHint),
            validator: (v) => (v ?? '').trim().isEmpty ? t('required') : null),
          const SizedBox(height: 22),
          LuiFormLabel(t('spending')),
          DropdownButtonFormField<String>(
            value: spending,
            isExpanded: true,
            decoration: const InputDecoration(),
            items: currencies.map((c) => DropdownMenuItem(
              value: c, child: Text(c))).toList(),
            onChanged: widget.initial == null ? (v) {
              if (v != null) setState(() {
                spending = v;
                if (spending == settlement) rate.text = '1';
              });
            } : null,
          ),
          const SizedBox(height: 18),
          LuiFormLabel(t('settlement')),
          DropdownButtonFormField<String>(
            value: settlement,
            isExpanded: true,
            decoration: const InputDecoration(),
            items: currencies.map((c) => DropdownMenuItem(
              value: c, child: Text(c))).toList(),
            onChanged: widget.initial == null ? (v) {
              if (v != null) setState(() {
                settlement = v;
                if (spending == settlement) rate.text = '1';
              });
            } : null,
          ),
          const SizedBox(height: 22),
          LuiFormLabel(t('rate')),
          TextFormField(
            controller: rate,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.currency_exchange_outlined),
              helperText: l.rateHint,
              helperMaxLines: 2,
            ),
            validator: (v) {
              final n = double.tryParse(v ?? '');
              return n == null || !n.isFinite || n <= 0 ? t('invalid') : null;
            }),
          const SizedBox(height: 22),
          LuiFormLabel(t('budget')),
          TextFormField(
            controller: budget,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              hintText: '0.00',
              suffixText: spending,
            ),
            validator: (v) {
              if ((v ?? '').trim().isEmpty) return null;
              final n = double.tryParse(v!);
              return n == null || !n.isFinite || n < 0 ? t('invalid') : null;
            }),
          const SizedBox(height: 30),
          FilledButton(
            onPressed: () {
              if (!form.currentState!.validate()) return;
              Navigator.pop(context, Group(
                widget.initial?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
                name.text.trim(), travel, spending, settlement,
                double.parse(rate.text),
                budget.text.trim().isEmpty ? null : double.parse(budget.text)));
            },
            child: Text(widget.initial == null ? t('create') : l.saveChanges),
          ),
        ]),
      )),
    );
  }
}

class GroupPage extends StatelessWidget {
  const GroupPage({super.key, required this.group, required this.t});
  final Group group;
  final String Function(String) t;
  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(group.name)),
    body: ListView(padding: const EdgeInsets.fromLTRB(20, 16, 20, 32), children: [
      Text(group.name, style: Theme.of(context).textTheme.headlineMedium?.copyWith(
        fontWeight: FontWeight.w700, letterSpacing: -0.8)),
      const SizedBox(height: 8),
      Text('1 ' + group.settlement + ' = ' + group.rate.toString() +
        ' ' + group.spending,
        style: Theme.of(context).textTheme.bodyMedium),
      if (group.budget != null) ...[
        const SizedBox(height: 12),
        Text(t('budget') + ': ' + group.budget.toString() + ' ' + group.spending),
      ],
      const SizedBox(height: 28),
      Card(child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline_rounded,
              color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 12),
            Text(t('localOnlyFeatures'),
              style: Theme.of(context).textTheme.bodyMedium),
            if (cloudEnabled) ...[
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const SharedGroupsPage())),
                icon: const Icon(Icons.groups_2_outlined),
                label: Text(t('openSharedGroups')),
              ),
            ],
          ]),
      )),
      const SizedBox(height: 24),
      Text(t('local'), style: Theme.of(context).textTheme.bodySmall),
    ]),
  );
}

class Settings extends StatefulWidget {
  const Settings({super.key, required this.t, required this.mode,
    required this.language, required this.onMode, required this.onLanguage});

  final String Function(String) t;
  final ThemeMode mode;
  final String language;
  final ValueChanged<ThemeMode> onMode;
  final ValueChanged<String> onLanguage;

  @override State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  late ThemeMode selectedMode;
  late String selectedLanguage;
  String preferredRepaymentCurrency = 'SGD';

  @override
  void initState() {
    super.initState();
    selectedMode = widget.mode;
    selectedLanguage = widget.language;
    loadPreferredCurrency();
  }

  Future<void> loadPreferredCurrency() async {
    final currency = await RepaymentPreferences.getDefault();
    if (mounted) setState(() => preferredRepaymentCurrency = currency);
  }

  Future<void> choosePreferredCurrency(String currency) async {
    await RepaymentPreferences.setDefault(currency);
    if (mounted) setState(() => preferredRepaymentCurrency = currency);
  }

  @override
  void didUpdateWidget(covariant Settings oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.mode != oldWidget.mode) selectedMode = widget.mode;
    if (widget.language != oldWidget.language) selectedLanguage = widget.language;
  }

  void changeTheme(ThemeMode value) {
    setState(() => selectedMode = value);
    widget.onMode(value);
  }

  void changeLanguage(String value) {
    setState(() => selectedLanguage = value);
    widget.onLanguage(value);
  }

  Widget sectionHeader(String title, String description) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w700, letterSpacing: -0.2)),
      const SizedBox(height: 4),
      Text(description, style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant)),
    ]),
  );

  Widget choiceTile({
    required String title,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final colors = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(children: [
          Icon(icon, size: 21,
            color: selected ? colors.primary : colors.onSurfaceVariant),
          const SizedBox(width: 14),
          Expanded(child: Text(title, style: TextStyle(
            fontSize: 15, fontWeight: selected ? FontWeight.w600 : FontWeight.w400))),
          if (selected) Icon(Icons.check_circle_rounded,
            size: 21, color: colors.primary),
        ]),
      ),
    );
  }

  Widget choiceCard(List<Widget> items) => Card(
    clipBehavior: Clip.antiAlias,
    child: Column(children: [
      for (var i = 0; i < items.length; i++) ...[
        if (i > 0) const Divider(height: 1, indent: 50),
        items[i],
      ],
    ]),
  );

  @override Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l.settings)),
      body: ListView(padding: const EdgeInsets.fromLTRB(20, 20, 20, 36), children: [
        Text(l.settingsIntro,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant)),
        const SizedBox(height: 30),
        sectionHeader(l.theme, l.appearanceHint),
        choiceCard([
          choiceTile(
            title: l.system, icon: Icons.brightness_auto_outlined,
            selected: selectedMode == ThemeMode.system,
            onTap: () => changeTheme(ThemeMode.system)),
          choiceTile(
            title: l.light, icon: Icons.light_mode_outlined,
            selected: selectedMode == ThemeMode.light,
            onTap: () => changeTheme(ThemeMode.light)),
          choiceTile(
            title: l.dark, icon: Icons.dark_mode_outlined,
            selected: selectedMode == ThemeMode.dark,
            onTap: () => changeTheme(ThemeMode.dark)),
        ]),
        const SizedBox(height: 30),
        sectionHeader(l.language, l.languageHint),
        choiceCard([
          choiceTile(
            title: 'English', icon: Icons.language_outlined,
            selected: selectedLanguage == 'en',
            onTap: () => changeLanguage('en')),
          choiceTile(
            title: '简体中文', icon: Icons.translate_outlined,
            selected: selectedLanguage == 'zh',
            onTap: () => changeLanguage('zh')),
        ]),
        const SizedBox(height: 30),
        sectionHeader(l.repaymentDefaultCurrency, l.repaymentDefaultCurrencyHint),
        choiceCard([
          choiceTile(
            title: 'SGD', icon: Icons.payments_outlined,
            selected: preferredRepaymentCurrency == 'SGD',
            onTap: () => choosePreferredCurrency('SGD')),
          choiceTile(
            title: 'MYR', icon: Icons.currency_exchange_outlined,
            selected: preferredRepaymentCurrency == 'MYR',
            onTap: () => choosePreferredCurrency('MYR')),
        ]),
        const SizedBox(height: 34),
        Center(child: Text(l.version,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant))),
      ]),
    );
  }
}
