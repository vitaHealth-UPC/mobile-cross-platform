import '../../../../shared/common/result/app_result.dart';
import '../readmodels/alert_timeline.dart';

/// Alerts and the day's doses read together, so a failed source never becomes a misleading
/// empty section.
abstract interface class AlertTimelineReader {
  Future<AppResult<AlertTimeline>> read(String olderAdultId, DateTime day);
}
