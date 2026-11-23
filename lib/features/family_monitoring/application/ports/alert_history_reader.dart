import '../../../../shared/common/result/app_result.dart';
import '../readmodels/recorded_alert_event.dart';

/// Steps the backend recorded for one alert.
abstract interface class AlertHistoryReader {
  Future<AppResult<List<RecordedAlertEvent>>> read(
    String olderAdultId,
    int alertId,
  );
}
