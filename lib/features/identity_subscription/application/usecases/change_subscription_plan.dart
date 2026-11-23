import '../../../../shared/common/result/app_result.dart';
import '../../domain/entities/subscription_plan.dart';
import '../ports/subscription_repository.dart';

/// Activates another plan for the account (US-45).
final class ChangeSubscriptionPlan {
  const ChangeSubscriptionPlan(this._repository);
  final SubscriptionRepository _repository;

  Future<AppResult<AccountSubscription>> call(String planCode) {
    final code = planCode.trim();
    if (code.isEmpty) return Future.value(const AppFailure('PLAN_NOT_FOUND'));
    return _repository.change(code);
  }
}
