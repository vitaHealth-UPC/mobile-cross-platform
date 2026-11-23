import '../../../../shared/common/result/app_result.dart';
import '../../domain/entities/caregiver_alert.dart';
import '../failure_codes.dart';
import '../policies/alert_ordering.dart';
import '../ports/alert_timeline_reader.dart';
import '../readmodels/alert_timeline.dart';

/// Alerts and the doses of [day] together.
final class GetAlertTimeline {
  const GetAlertTimeline(this._reader);
  final AlertTimelineReader _reader;

  Future<AppResult<AlertTimeline>> call(
    String olderAdultId,
    DateTime day,
  ) async {
    if (olderAdultId.trim().isEmpty) {
      return const AppFailure(MonitoringFailureCodes.invalidReference);
    }
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
