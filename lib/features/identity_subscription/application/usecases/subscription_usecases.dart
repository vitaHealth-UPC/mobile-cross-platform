import '../../../../shared/common/result/app_result.dart';
import '../../domain/entities/subscription_plan.dart';
import '../ports/public_plan_catalog.dart';
import '../ports/subscription_repository.dart';

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
