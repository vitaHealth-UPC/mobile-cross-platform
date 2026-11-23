import '../../../../shared/common/result/app_result.dart';
import '../readmodels/family_summary.dart';
import '../readmodels/intake_history_entry.dart';

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
