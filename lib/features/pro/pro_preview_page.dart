import 'package:flutter/material.dart';
import 'pro_plans.dart';

/// Informational preview only. No checkout is offered until both app stores
/// and the trusted server-side receipt verification are implemented.
class ProPreviewPage extends StatelessWidget {
  const ProPreviewPage({super.key, required this.language});
  final String language;

  bool get zh => language == 'zh';
  String tr(String english, String chinese) => zh ? chinese : english;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('SplitLui Pro')),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
          children: [
            Icon(Icons.workspace_premium_rounded, size: 48, color: cs.primary),
            const SizedBox(height: 12),
            Text(tr('More flexibility for your groups', '让每个群组更灵活'),
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(
              tr('Your existing shared expenses, repayments and Common Fund '
                 'remain available for free while Pro is being developed.',
                 'Pro 功能仍在开发中。现有的共同开销、还款和共同基金功能继续免费使用。'),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium),
            const SizedBox(height: 24),
            ...[
              (Icons.groups_outlined, tr('Unlimited groups', '无限群组')),
              (Icons.document_scanner_outlined,
                tr('Higher receipt scanning limits', '更高的收据扫描额度')),
              (Icons.picture_as_pdf_outlined,
                tr('Advanced trip reports', '高级旅程报告')),
              (Icons.insights_outlined,
                tr('Advanced spending insights', '高级开销分析')),
            ].map((feature) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(children: [
                Icon(feature.$1, color: cs.primary),
                const SizedBox(width: 14),
                Expanded(child: Text(feature.$2)),
              ]),
            )),
            const SizedBox(height: 12),
            Text(tr('Planned options', '计划推出的方案'),
              style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            for (final plan in ProPlan.values)
              Card(child: ListTile(
                leading: Icon(plan.permanent
                    ? Icons.all_inclusive_rounded
                    : Icons.event_repeat_rounded),
                title: Text(switch(plan) {
                  ProPlan.monthly => tr('Monthly Pro', '月付 Pro'),
                  ProPlan.yearly => tr('Yearly Pro', '年付 Pro'),
                  ProPlan.lifetime => tr('Lifetime Pro', '永久 Pro'),
                }),
                subtitle: Text(tr(
                  'Pricing and checkout will appear after store approval.',
                  '商店审核及付款功能准备好后才会显示正式价格。')),
              )),
            const SizedBox(height: 16),
            Card(
              color: cs.surfaceContainerLow,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(tr(
                  'Coming soon. No payment will be taken on this screen. '
                  'Subscriptions and lifetime purchases require account-linked, '
                  'store-verified access and a way to restore purchases.',
                  '即将推出。此页面不会收取费用。订阅及永久购买将需要与账号关联、'
                  '经过应用商店验证，并支持恢复购买。')),
              )),
          ],
        ),
      ),
    );
  }
}
