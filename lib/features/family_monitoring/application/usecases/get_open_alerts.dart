import '../../../../shared/common/result/app_result.dart';
import '../../domain/entities/caregiver_alert.dart';
import '../../domain/repositories/alerts_repository.dart';
import '../failure_codes.dart';
import '../policies/alert_ordering.dart';

/// Alerts that still need attention, in follow-up order.
final class GetOpenAlerts {
  const GetOpenAlerts(this._repository);
  final AlertsRepository _repository;

  Future<AppResult<List<CaregiverAlert>>> call(String olderAdultId) async {
    if (olderAdultId.trim().isEmpty) {
      return const AppFailure(MonitoringFailureCodes.invalidReference);
    }
    return switch (await _repository.openAlerts(olderAdultId.trim())) {
      AppSuccess(:final value) => AppSuccess(
        List.unmodifiable(<CaregiverAlert>[...value]..sort(compareAlerts)),
      ),
      AppFailure(:final code) => AppFailure(code),
    };
  }
}
