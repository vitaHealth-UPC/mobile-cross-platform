import '../../../../shared/common/result/app_result.dart';
import '../../domain/entities/subscription_plan.dart';
import '../ports/subscription_repository.dart';

/// Current subscription and the catalog, read together so a plan can be compared (US-44).
final class GetSubscriptionOverview {
  const GetSubscriptionOverview(this._repository);
  final SubscriptionRepository _repository;

  Future<AppResult<(AccountSubscription, List<SubscriptionPlan>)>>
  call() async {
    final current = await _repository.current();
    if (current case AppFailure(:final code)) return AppFailure(code);
    final plans = await _repository.plans();
    if (plans case AppFailure(:final code)) return AppFailure(code);
    return AppSuccess((
      (current as AppSuccess<AccountSubscription>).value,
      (plans as AppSuccess<List<SubscriptionPlan>>).value,
    ));
  }
}
