import '../../../../shared/common/result/app_result.dart';
import '../readmodels/monitored_person.dart';

/// Reads the linked person profile without exposing its transport representation.
abstract interface class MonitoredPersonReader {
  Future<AppResult<MonitoredPerson>> read(String olderAdultId);
}
