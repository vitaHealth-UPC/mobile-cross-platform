import '../../../../shared/common/result/app_result.dart';
import '../../domain/entities/subscription_plan.dart';
import '../ports/public_plan_catalog.dart';

/// Public catalog for a visitor, ordered from the lowest monthly price (US-48).
final class GetPublicPlans {
  const GetPublicPlans(this._catalog);
  final PublicPlanCatalog _catalog;

  Future<AppResult<List<SubscriptionPlan>>> call() async =>
      switch (await _catalog.plans()) {
        AppSuccess(:final value) => AppSuccess(
          [...value]..sort((a, b) => a.monthlyPrice.compareTo(b.monthlyPrice)),
        ),
        AppFailure(:final code) => AppFailure(code),
      };
}
