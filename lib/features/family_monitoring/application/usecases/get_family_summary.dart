import '../../../../shared/common/result/app_result.dart';
import '../failure_codes.dart';
import '../ports/family_monitoring_repository.dart';
import '../readmodels/family_summary.dart';

/// The caller-selected calendar day and the account-scoped summary projection.
final class GetFamilySummary {
  const GetFamilySummary(this._repository);
  final FamilyMonitoringRepository _repository;

  Future<AppResult<FamilySummary>> call(
    String olderAdultId,
    String name,
    DateTime day,
  ) async {
    if (olderAdultId.trim().isEmpty) {
      return const AppFailure(MonitoringFailureCodes.invalidReference);
    }
    return _repository.summary(olderAdultId.trim(), name, day);
  }
}
