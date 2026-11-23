import '../../../../shared/common/result/app_result.dart';
import '../../domain/entities/caregiver_alert.dart';
import '../../domain/repositories/alerts_repository.dart';
import '../../domain/value_objects/alert_status.dart';
import '../failure_codes.dart';

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
    if (olderAdultId.trim().isEmpty || alertId <= 0) {
      return const AppFailure(MonitoringFailureCodes.invalidReference);
    }
    if (status == AlertStatus.open) {
      return const AppFailure(MonitoringFailureCodes.statusNotAccepted);
    }
    return _repository.updateStatus(olderAdultId.trim(), alertId, status);
  }
}
