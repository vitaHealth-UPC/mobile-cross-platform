import '../../../../shared/common/result/app_result.dart';
import '../../domain/entities/subscription_plan.dart';

/// Plans a visitor can compare before creating an account (US-48).
abstract interface class PublicPlanCatalog {
  Future<AppResult<List<SubscriptionPlan>>> plans();
}
