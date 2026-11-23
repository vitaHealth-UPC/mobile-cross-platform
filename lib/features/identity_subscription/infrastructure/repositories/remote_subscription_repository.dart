import '../../../../shared/application/session/session_owner.dart';
import '../../../../shared/application/session/session_store.dart';
import '../../../../shared/common/result/app_result.dart';
import '../../../../shared/infrastructure/network/api_response.dart';
import '../../../../shared/infrastructure/session/authorized_request.dart';
import '../../application/ports/subscription_repository.dart';
import '../../domain/entities/subscription_plan.dart';
import '../mappers/subscription_mapper.dart';
import '../remote/subscription_api.dart';

/// Subscription of the caregiver's own account: the account id sent to the
/// server is always the captured session owner, never a value from the screen.
final class RemoteSubscriptionRepository implements SubscriptionRepository {
  const RemoteSubscriptionRepository({
    required this._api,
    required this._store,
  });
  final SubscriptionApi _api;
  final SessionStore _store;

  @override
  Future<AppResult<List<SubscriptionPlan>>> plans() => authorizedRequest(
    _store,
    const {SessionRole.caregiver},
    (session) => _api.plans(session.accessToken),
    (response, _) => response.status == 200
        ? AppSuccess(SubscriptionMapper.plans(response.body))
        : _failure(response),
  );

  @override
  Future<AppResult<AccountSubscription>> current() => authorizedRequest(
    _store,
    const {SessionRole.caregiver},
    (session) => _api.current(session.owner.id, session.accessToken),
    (response, owner) => _subscription(response, owner, null),
  );

  @override
  Future<AppResult<AccountSubscription>> change(String planCode) =>
      authorizedRequest(
        _store,
        const {SessionRole.caregiver},
        (session) =>
            _api.change(session.owner.id, planCode, session.accessToken),
        (response, owner) => _subscription(response, owner, planCode),
      );

  /// A receipt must be for this account and, after a change, show the chosen plan.
  AppResult<AccountSubscription> _subscription(
    ApiResponse response,
    SessionOwner owner,
    String? requested,
  ) {
    if (response.status != 200) return _failure(response);
    final subscription = SubscriptionMapper.subscription(response.body);
    final acknowledged =
        requested == null ||
        (subscription.active &&
            subscription.plan.code.toUpperCase() == requested.toUpperCase());
    return subscription.accountId == owner.id && acknowledged
        ? AppSuccess(subscription)
        : const AppFailure('INVALID_RESPONSE');
  }

  static AppFailure<T> _failure<T>(ApiResponse response) {
    final body = response.body;
    final code = body is Map<String, Object?> ? body['title'] : null;
    const known = {'PLAN_NOT_FOUND', 'ACCOUNT_NOT_FOUND'};
    if (code is String && known.contains(code)) return AppFailure(code);
    return AppFailure(
      response.status == 404 ? 'PLAN_NOT_FOUND' : 'REQUEST_FAILED',
    );
  }
}
