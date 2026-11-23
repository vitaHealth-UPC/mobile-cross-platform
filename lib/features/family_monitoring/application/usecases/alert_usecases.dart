import '../../../../shared/common/result/app_result.dart';
import '../../domain/entities/caregiver_alert.dart';
import '../../domain/repositories/monitoring_repositories.dart';
import '../../domain/value_objects/alert_status.dart';
import '../failure_codes.dart';
import '../ports/monitoring_ports.dart';
import '../readmodels/monitoring_readmodels.dart';

/// Pending alerts first, then attended and closed ones; the most recent intake first inside
/// each group.
int compareAlerts(CaregiverAlert a, CaregiverAlert b) {
  final byStatus = a.status.index.compareTo(b.status.index);
  return byStatus != 0 ? byStatus : b.scheduledAt.compareTo(a.scheduledAt);
}

AppFailure<T> _invalid<T>() =>
    const AppFailure(MonitoringFailureCodes.invalidReference);

/// Alerts that still need attention, in follow-up order.
final class GetOpenAlerts {
  const GetOpenAlerts(this._repository);
  final AlertsRepository _repository;

  Future<AppResult<List<CaregiverAlert>>> call(String olderAdultId) async {
    if (olderAdultId.trim().isEmpty) return _invalid();
    return switch (await _repository.openAlerts(olderAdultId.trim())) {
      AppSuccess(:final value) => AppSuccess(
        List.unmodifiable(<CaregiverAlert>[...value]..sort(compareAlerts)),
      ),
      AppFailure(:final code) => AppFailure(code),
    };
  }
}

final class GetAlertDetail {
  const GetAlertDetail(this._repository);
  final AlertsRepository _repository;

  Future<AppResult<CaregiverAlert>> call(
    String olderAdultId,
    int alertId,
  ) async {
    if (olderAdultId.trim().isEmpty || alertId <= 0) return _invalid();
    return _repository.alert(olderAdultId.trim(), alertId);
  }
}

/// Attends or closes an alert. `OPEN` is never sent: the backend only accepts `ATTENDED`
/// and `CLOSED`.
final class UpdateAlertStatus {
  const UpdateAlertStatus(this._repository);
  final AlertsRepository _repository;

  Future<AppResult<CaregiverAlert>> call(
    String olderAdultId,
    int alertId,
    AlertStatus status,
  ) async {
    if (olderAdultId.trim().isEmpty || alertId <= 0) return _invalid();
    if (status == AlertStatus.open) {
      return const AppFailure(MonitoringFailureCodes.statusNotAccepted);
    }
    return _repository.updateStatus(olderAdultId.trim(), alertId, status);
  }
}

/// Alerts and the doses of [day] together.
final class GetAlertTimeline {
  const GetAlertTimeline(this._reader);
  final AlertTimelineReader _reader;

  Future<AppResult<AlertTimeline>> call(
    String olderAdultId,
    DateTime day,
  ) async {
    if (olderAdultId.trim().isEmpty) return _invalid();
    return switch (await _reader.read(olderAdultId.trim(), day)) {
      AppSuccess(:final value) => AppSuccess(
        AlertTimeline(
          alerts: List.unmodifiable(
            <CaregiverAlert>[...value.alerts]..sort(compareAlerts),
          ),
          doses: value.doses,
          olderAdultName: value.olderAdultName,
          day: value.day,
        ),
      ),
      AppFailure(:final code) => AppFailure(code),
    };
  }
}
