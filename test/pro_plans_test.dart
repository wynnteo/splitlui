import 'package:flutter_test/flutter_test.dart';
import 'package:splitlui/features/pro/pro_plans.dart';

void main() {
  test('three unique store product IDs', () {
    expect(ProPlan.values.length, 3);
    expect(ProPlan.productIds.length, 3);
    for (final plan in ProPlan.values) {
      expect(ProPlan.fromProductId(plan.productId), plan);
    }
    expect(ProPlan.fromProductId('unknown'), isNull);
  });

  test('unverified purchases never grant Pro', () {
    expect(ProEntitlement.unavailable.hasPro, isFalse);
    expect(const ProEntitlement(verified: false, active: true).hasPro, isFalse);
    expect(const ProEntitlement(verified: true, active: false).hasPro, isFalse);
  });

  test('expired subscriptions do not grant Pro', () {
    final expired = ProEntitlement(
      verified: true, active: true,
      expiresAt: DateTime.now().subtract(const Duration(days: 1)),
    );
    final lifetime = ProEntitlement(
      verified: true, active: true,
      productId: ProPlan.lifetime.productId,
    );
    expect(expired.hasPro, isFalse);
    expect(lifetime.hasPro, isTrue);
  });
}
