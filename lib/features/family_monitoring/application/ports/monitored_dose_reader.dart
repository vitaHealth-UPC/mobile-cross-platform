import '../../../../shared/common/result/app_result.dart';
import '../readmodels/monitored_dose.dart';

/// Reads one scheduled intake within the caller-authorized older adult scope.
abstract interface class MonitoredDoseReader {
  Future<AppResult<MonitoredDose>> read(String olderAdultId, String intakeId);
}
