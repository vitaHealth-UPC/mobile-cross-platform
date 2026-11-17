/// Product capability a plan enables, as the server names it.
enum PlanCapability {
  reminders('REMINDERS'),
  agenda('AGENDA'),
  intakeConfirmation('INTAKE_CONFIRMATION'),
  familyAlerts('FAMILY_ALERTS'),
  familyMonitoring('FAMILY_MONITORING'),
  adherenceInsights('ADHERENCE_INSIGHTS');

  const PlanCapability(this.code);
  final String code;

  /// Null for a capability this version of the app does not know yet.
  static PlanCapability? fromCode(Object? code) {
    for (final value in values) {
      if (value.code == code) return value;
    }
    return null;
  }
}

/// A plan of the catalog (US-44). The price is what the server publishes.
final class SubscriptionPlan {
  SubscriptionPlan({
    required this.code,
    required this.name,
    required this.monthlyPrice,
    required this.currency,
    required Set<PlanCapability> capabilities,
  }) : capabilities = Set.unmodifiable(capabilities) {
    if (code.trim().isEmpty ||
        name.trim().isEmpty ||
        monthlyPrice < 0 ||
        currency.trim().isEmpty) {
      throw ArgumentError('Invalid plan');
    }
  }

  final String code;
  final String name;
  final num monthlyPrice;
  final String currency;
  final Set<PlanCapability> capabilities;
}

/// The plan an account has now and when it renews (US-44, US-45).
final class AccountSubscription {
  AccountSubscription({
    required this.accountId,
    required this.plan,
    required this.active,
    this.renewsAt,
  }) {
    if (accountId.trim().isEmpty) throw ArgumentError('Invalid subscription');
  }

  final String accountId;
  final SubscriptionPlan plan;
  final bool active;

  /// Null when the server has no renewal on record.
  final DateTime? renewsAt;

  bool isOn(SubscriptionPlan other) => active && plan.code == other.code;
}
