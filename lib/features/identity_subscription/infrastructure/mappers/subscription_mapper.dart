import '../../domain/entities/subscription_plan.dart';

/// Reads plan and subscription resources; anything malformed throws FormatException.
abstract final class SubscriptionMapper {
  static List<SubscriptionPlan> plans(Object? body) {
    if (body is! List) throw const FormatException('Plans expected');
    return [for (final item in body) plan(item)];
  }

  static SubscriptionPlan plan(Object? body) {
    if (body is! Map<String, Object?>) {
      throw const FormatException('Plan expected');
    }
    final price = body['monthlyPrice'];
    final capabilities = body['capabilities'];
    if (price is! num || capabilities is! List) {
      throw const FormatException('Plan');
    }
    try {
      return SubscriptionPlan(
        code: _text(body, 'code'),
        name: _text(body, 'name'),
        monthlyPrice: price,
        currency: _text(body, 'currency'),
        // A capability added on the server later is ignored, not invented.
        capabilities: {
          for (final code in capabilities) ?PlanCapability.fromCode(code),
        },
      );
    } on ArgumentError {
      throw const FormatException('Invalid plan');
    }
  }

  static AccountSubscription subscription(Object? body) {
    if (body is! Map<String, Object?>) {
      throw const FormatException('Subscription expected');
    }
    final renews = body['renewsAt'];
    if (renews != null && renews is! String) {
      throw const FormatException('renewsAt');
    }
    final renewsAt = renews == null ? null : DateTime.parse(renews as String);
    if (renewsAt != null && !renewsAt.isUtc) {
      throw const FormatException('renewsAt');
    }
    try {
      return AccountSubscription(
        accountId: _text(body, 'accountId'),
        plan: plan(body['plan']),
        active: body['status'] == 'ACTIVE',
        renewsAt: renewsAt,
      );
    } on ArgumentError {
      throw const FormatException('Invalid subscription');
    }
  }

  static String _text(Map<String, Object?> body, String key) {
    final value = body[key];
    if (value is! String || value.trim().isEmpty) throw FormatException(key);
    return value;
  }
}
