import '../../../../shared/common/result/app_result.dart';
import '../readmodels/monitoring_readmodels.dart';

/// Reads protected family summaries and intake history. [day] is a calendar day of the
/// device's time zone; implementations turn it into instants.
abstract interface class FamilyMonitoringRepository {
  Future<AppResult<FamilySummary>> summary(
    String olderAdultId,
    String name,
    DateTime day,
  );

  Future<AppResult<List<IntakeHistoryEntry>>> history(String olderAdultId);
}

/// Alerts and the day's doses read together, so a failed source never becomes a misleading
/// empty section.
abstract interface class AlertTimelineReader {
  Future<AppResult<AlertTimeline>> read(String olderAdultId, DateTime day);
}

/// Steps the backend recorded for one alert.
abstract interface class AlertHistoryReader {
  Future<AppResult<List<RecordedAlertEvent>>> read(
    String olderAdultId,
    int alertId,
  );
}

abstract interface class MonitoredDoseReader {
  Future<AppResult<MonitoredDose>> read(String olderAdultId, String intakeId);
}

abstract interface class MonitoredPersonReader {
  Future<AppResult<MonitoredPerson>> read(String olderAdultId);
}

/// Resolves the contact channel and display name as one follow-up operation.
abstract interface class ContactOptionReader {
  Future<AppResult<ContactOption>> call(String olderAdultId);
}
