import '../../../../shared/application/session/session_store.dart';
import '../../../../shared/common/result/app_result.dart';
import '../../application/failure_codes.dart';
import '../../domain/entities/caregiver_alert.dart';
import '../../domain/repositories/monitoring_repositories.dart';
import '../../domain/value_objects/alert_status.dart';
import '../mappers/monitoring_mapper.dart';
import '../remote/family_monitoring_api.dart';
import 'monitoring_requests.dart';

/// There is no alert list endpoint: the list comes from the open alerts of the recent status
/// (`GET /older-adults/{id}/status`) and the detail from `GET .../alerts/{alertId}`.
final class RemoteAlertsRepository implements AlertsRepository {
  const RemoteAlertsRepository({required this._api, required this._store});
  final FamilyMonitoringApi _api;
  final SessionStore _store;

  @override
  Future<AppResult<List<CaregiverAlert>>> openAlerts(String olderAdultId) =>
      caregiverMonitoringRequest(
        _store,
        (session) =>
            _api.status(olderAdultId, session.owner.id, session.accessToken),
        (response, _) =>
            AppSuccess(MonitoringMapper.status(response.body).openAlerts),
      );

  @override
  Future<AppResult<CaregiverAlert>> alert(String olderAdultId, int alertId) =>
      caregiverMonitoringRequest(
        _store,
        (session) => _api.alert(
          olderAdultId,
          alertId,
          session.owner.id,
          session.accessToken,
        ),
        (response, _) {
          final alert = MonitoringMapper.alert(response.body);
          return alert.id == alertId
              ? AppSuccess(alert)
              : const AppFailure('INVALID_RESPONSE');
        },
      );

  @override
  Future<AppResult<CaregiverAlert>> updateStatus(
    String olderAdultId,
    int alertId,
    AlertStatus status,
  ) => caregiverMonitoringRequest(
    _store,
    (session) => _api.updateAlertStatus(
      olderAdultId,
      alertId,
      session.owner.id,
      status.wireName,
      session.accessToken,
    ),
    (response, _) {
      final alert = MonitoringMapper.alert(response.body);
      return alert.id == alertId && alert.status == status
          ? AppSuccess(alert)
          : const AppFailure('INVALID_RESPONSE');
    },
    badRequest: MonitoringFailureCodes.statusNotAccepted,
  );
}
