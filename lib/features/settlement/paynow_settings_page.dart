import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../ui/lui_style.dart';

/// PayNow phone numbers are optional, scoped to ONE group and visible to all
/// members of that group. Never store bank credentials or transfer money.
class GroupPayNowApi {
  final SupabaseClient db = Supabase.instance.client;

  Future<Map<String, String>> getAll(String groupId) async {
    final rows = await db.from('trip_paynow_details')
      .select('user_id,mobile').eq('group_id',groupId);
    return {
      for (final row in rows)
        row['user_id'] as String: row['mobile'] as String,
    };
  }

  Future<void> setOwn(String groupId, String mobile) async {
    await db.rpc('set_trip_paynow_mobile',
      params: {'p_group':groupId, 'p_mobile':mobile.trim()});
  }
}

class PayNowSettingsPage extends StatefulWidget {
  const PayNowSettingsPage({
    super.key, required this.groupId, required this.groupName,
  });
  final String groupId, groupName;

  @override
  State<PayNowSettingsPage> createState() => _PayNowSettingsPageState();
}

class _PayNowSettingsPageState extends State<PayNowSettingsPage> {
  final api = GroupPayNowApi();
  final form = GlobalKey<FormState>();
  final controller = TextEditingController();
  bool busy = true;
  String? error;

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> load() async {
    try {
      final currentUserId = Supabase.instance.client.auth.currentUser?.id;
      final records = await api.getAll(widget.groupId);
      if (mounted) {
        setState(() {
          controller.text = records[currentUserId] ?? '';
          busy = false;
          error = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() {busy = false;error = e.toString();});
    }
  }

  Future<void> save() async {
    if (busy || !(form.currentState?.validate() ?? false)) return;
    setState(() {busy = true;error = null;});
    try {
      await api.setOwn(widget.groupId,controller.text);
      if (mounted) Navigator.pop(context,true);
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l.payNowDetails)),
      body: Form(
        key: form,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20,16,20,32),
          children: [
            Text(widget.groupName,
              style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 14),
            Text(l.payNowPrivacyWarning,
              style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 24),
            LuiFormLabel(l.payNowMobile),
            TextFormField(
              controller: controller,
              keyboardType: TextInputType.phone,
              enabled: !busy,
              decoration: InputDecoration(
                hintText: l.payNowMobileHint,
                prefixIcon: const Icon(Icons.phone_iphone_outlined),
              ),
              validator: (raw) {
                var value = (raw ?? '').replaceAll(RegExp(r'[\s-]'), '');
                if (value.startsWith('+65')) value = value.substring(3);
                if (value.startsWith('65') && value.length == 10) {
                  value = value.substring(2);
                }
                if (value.isEmpty) return null; // Empty removes details.
                if (!RegExp(r'^[89]\d{7}$').hasMatch(value)) return l.payNowInvalid;
                return null;
              },
            ),
            const SizedBox(height: 12),
            Text(l.payNowRemoveHint,
              style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 20),
            if (busy) const Center(child: CircularProgressIndicator()),
            if (error != null) Text(error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error)),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: busy ? null : save,
              icon: const Icon(Icons.save_outlined),
              label: Text(l.saveChanges),
            ),
          ],
        ),
      ),
    );
  }
}
