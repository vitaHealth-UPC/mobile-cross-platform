import '../../../../shared/common/result/app_result.dart';
import '../../domain/entities/subscription_plan.dart';
import '../ports/subscription_repository.dart';

/// Applies the plan a visitor chose once the new account has a session. A new
/// account starts on the server's default plan, so nothing is sent when the
/// choice already matches it.
final class ApplyChosenPlan {
  const ApplyChosenPlan(this._repository);
  final SubscriptionRepository _repository;

  Future<AppResult<AccountSubscription>> call(String planCode) async {
    final code = planCode.trim().toUpperCase();
    if (code.isEmpty) return const AppFailure('PLAN_NOT_FOUND');
    final current = await _repository.current();
    if (current case AppSuccess(:final value)
        when value.active && value.plan.code.toUpperCase() == code) {
      return current;
    }
    if (current case AppFailure(:final code)) return AppFailure(code);
    return _repository.change(code);
  }
}
