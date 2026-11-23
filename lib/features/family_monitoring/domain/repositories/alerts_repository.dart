import '../../../../shared/common/result/app_result.dart';
import '../entities/caregiver_alert.dart';
import '../value_objects/alert_status.dart';

/// Reads caregiver alerts and applies allowed status transitions. The caregiver is the
/// owner of the session in force, never an argument.
abstract interface class AlertsRepository {
  /// There is no alert list endpoint: these are the alerts that still need attention,
  /// taken from the recent status of the older adult.
  Future<AppResult<List<CaregiverAlert>>> openAlerts(String olderAdultId);

  Future<AppResult<CaregiverAlert>> alert(String olderAdultId, int alertId);

  Future<AppResult<CaregiverAlert>> updateStatus(
    String olderAdultId,
    int alertId,
    AlertStatus status,
  );
}
