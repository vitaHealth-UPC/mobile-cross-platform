import '../../../../shared/common/result/app_result.dart';
import '../../../../shared/infrastructure/network/api_response.dart';
import '../../application/ports/public_plan_catalog.dart';
import '../../domain/entities/subscription_plan.dart';
import '../mappers/subscription_mapper.dart';
import '../remote/subscription_api.dart';

/// Reads the public plan catalog without any session or credential.
final class RemotePublicPlanCatalog implements PublicPlanCatalog {
  const RemotePublicPlanCatalog(this._api);
  final SubscriptionApi _api;

  @override
  Future<AppResult<List<SubscriptionPlan>>> plans() async {
    try {
      final response = await _api.publicPlans();
      if (response.status == 429) return const AppFailure('RATE_LIMITED');
      if (response.status != 200) return const AppFailure('REQUEST_FAILED');
      final plans = SubscriptionMapper.plans(response.body);
      return plans.isEmpty
          ? const AppFailure('INVALID_RESPONSE')
          : AppSuccess(plans);
    } on ApiTransportException catch (error) {
      return AppFailure(error.code);
    } on FormatException {
      return const AppFailure('INVALID_RESPONSE');
    } on ArgumentError {
      return const AppFailure('INVALID_RESPONSE');
    }
  }
}
