import '../../../../shared/common/result/app_result.dart';
import '../failure_codes.dart';
import '../ports/family_monitoring_repository.dart';
import '../readmodels/intake_history_entry.dart';

/// Recent intake history of one adult, read with the caregiver's own authorization.
final class GetFamilyHistory {
  const GetFamilyHistory(this._repository);
  final FamilyMonitoringRepository _repository;

  Future<AppResult<List<IntakeHistoryEntry>>> call(String olderAdultId) async {
    if (olderAdultId.trim().isEmpty) {
      return const AppFailure(MonitoringFailureCodes.invalidReference);
    }
    return _repository.history(olderAdultId.trim());
  }
}
