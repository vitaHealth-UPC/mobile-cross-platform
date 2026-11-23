import '../../../../shared/common/result/app_result.dart';
import '../../domain/entities/caregiver_alert.dart';
import '../../domain/repositories/alerts_repository.dart';
import '../failure_codes.dart';

/// Rejects invalid references before loading an alert for the selected older adult.
final class GetAlertDetail {
  const GetAlertDetail(this._repository);
  final AlertsRepository _repository;

  Future<AppResult<CaregiverAlert>> call(
    String olderAdultId,
    int alertId,
  ) async {
    if (olderAdultId.trim().isEmpty || alertId <= 0) {
      return const AppFailure(MonitoringFailureCodes.invalidReference);
    }
    return _repository.alert(olderAdultId.trim(), alertId);
  }
}
