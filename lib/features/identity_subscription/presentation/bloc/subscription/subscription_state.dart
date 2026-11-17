import '../../../domain/entities/subscription_plan.dart';

/// Observable phases of Figma 563:1701 and 563:5354.
enum SubscriptionPhase { loading, failure, ready }

final class SubscriptionState {
  const SubscriptionState({
    this.phase = SubscriptionPhase.loading,
    this.subscription,
    this.plans = const [],
    this.selectedCode,
    this.changing = false,
    this.updated = false,
    this.errorCode,
  });

  final SubscriptionPhase phase;
  final AccountSubscription? subscription;
  final List<SubscriptionPlan> plans;

  /// Plan chosen to change to; never the current one.
  final String? selectedCode;
  final bool changing;

  /// The server acknowledged the last change (Figma 563:5354).
  final bool updated;

  /// Failure to read, or a change the server refused.
  final String? errorCode;

  SubscriptionPlan? get selected {
    for (final plan in plans) {
      if (plan.code == selectedCode) return plan;
    }
    return null;
  }

  SubscriptionState copyWith({
    String? selectedCode,
    bool clearSelection = false,
    bool? changing,
    String? errorCode,
  }) => SubscriptionState(
    phase: phase,
    subscription: subscription,
    plans: plans,
    selectedCode: clearSelection ? null : selectedCode ?? this.selectedCode,
    changing: changing ?? this.changing,
    errorCode: errorCode,
  );
}
