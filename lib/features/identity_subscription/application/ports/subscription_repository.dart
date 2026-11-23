import '../../../../shared/common/result/app_result.dart';
import '../../domain/entities/subscription_plan.dart';

/// Plans and the subscription of the signed-in caregiver's own account.
abstract interface class SubscriptionRepository {
  Future<AppResult<List<SubscriptionPlan>>> plans();

  Future<AppResult<AccountSubscription>> current();

  Future<AppResult<AccountSubscription>> change(String planCode);
}
