/// Product identifiers to create identically in Google Play and App Store Connect.
/// Display prices must come from the store, never these illustrative amounts.
enum ProPlan {
  monthly('splitlui_pro_monthly', false),
  yearly('splitlui_pro_yearly', false),
  lifetime('splitlui_pro_lifetime', true);

  const ProPlan(this.productId, this.permanent);
  final String productId;
  final bool permanent;

  static const productIds = <String>{
    'splitlui_pro_monthly',
    'splitlui_pro_yearly',
    'splitlui_pro_lifetime',
  };

  static ProPlan? fromProductId(String id) {
    for (final plan in values) {
      if (plan.productId == id) return plan;
    }
    return null;
  }
}

/// Do not trust a local preference or purchase-stream callback to grant Pro.
/// The backend must verify the store transaction and return the entitlement.
/// Until the verification backend ships, all existing features remain free.
class ProEntitlement {
  const ProEntitlement({
    required this.verified,
    required this.active,
    this.productId,
    this.expiresAt,
  });

  final bool verified;
  final bool active;
  final String? productId;
  final DateTime? expiresAt;

  bool get hasPro => verified && active &&
      (expiresAt == null || expiresAt!.isAfter(DateTime.now()));

  static const unavailable = ProEntitlement(verified: false, active: false);
}
