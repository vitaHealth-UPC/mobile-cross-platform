import '../../../../shared/application/session/session_store.dart';
import '../../../../shared/application/session/stored_session.dart';
import '../../../../shared/common/result/app_result.dart';
import '../../../../shared/infrastructure/network/api_response.dart';
import '../../domain/entities/treatment.dart';
import '../../domain/repositories/treatment_repositories.dart';
import '../../domain/value_objects/treatment_regimen.dart';
import '../../domain/value_objects/treatment_status.dart';
import '../mappers/treatment_mapper.dart';
import '../remote/treatment_api.dart';
import 'treatment_requests.dart';

/// Configures regimens and changes lifecycle state, requiring the server to acknowledge
/// exactly the regimen or status that was requested.
final class RemoteTreatmentLifecycleRepository
    implements TreatmentLifecycleRepository {
  const RemoteTreatmentLifecycleRepository({
    required this._api,
    required this._store,
  });
  final TreatmentApi _api;
  final SessionStore _store;

  @override
  Future<AppResult<Treatment>> configure(
    String treatmentId,
    String medicationId,
    TreatmentRegimen regimen,
  ) {
    final times = regimen.schedule.times.map((time) => '$time').toList();
    return caregiverTreatmentRequest(
      _store,
      (session) => _api.configureTreatment(treatmentId, {
        'caregiverId': session.owner.id,
        'medicationId': medicationId,
        'dose': regimen.dose.value,
        'frequency': regimen.frequency.value,
        'scheduledTimes': times,
        'instructions': regimen.instructions.value,
        'reminderLeadMinutes': regimen.reminderLeadMinutes,
        if (regimen.followUpDelay != null)
          'followUpDelayMinutes': regimen.followUpDelay!.value,
      }, session.accessToken),
      (response) {
        final detail = TreatmentMapper.detail(response.body);
        final acknowledged =
            detail.id == treatmentId &&
            detail.medicationId == medicationId &&
            detail.dose == regimen.dose.value &&
            detail.frequency == regimen.frequency.value &&
            detail.instructions == regimen.instructions.value &&
            detail.reminderLeadMinutes == regimen.reminderLeadMinutes &&
            detail.followUpDelayMinutes == regimen.followUpDelay?.value &&
            detail.scheduledTimes.join(',') == times.join(',');
        return acknowledged
            ? AppSuccess(TreatmentMapper.treatment(response.body))
            : const AppFailure('INVALID_RESPONSE');
      },
    );
  }

  @override
  Future<AppResult<Treatment>> activate(String treatmentId) => _transition(
    treatmentId,
    TreatmentStatus.active,
    (session) => _api.activateTreatment(
      treatmentId,
      session.owner.id,
      session.accessToken,
    ),
  );

  @override
  Future<AppResult<Treatment>> pause(String treatmentId) => _transition(
    treatmentId,
    TreatmentStatus.paused,
    (session) =>
        _api.pauseTreatment(treatmentId, session.owner.id, session.accessToken),
  );

  @override
  Future<AppResult<Treatment>> resume(String treatmentId) => _transition(
    treatmentId,
    TreatmentStatus.active,
    (session) => _api.resumeTreatment(
      treatmentId,
      session.owner.id,
      session.accessToken,
    ),
  );

  Future<AppResult<Treatment>> _transition(
    String treatmentId,
    TreatmentStatus expected,
    Future<ApiResponse> Function(StoredSession) request,
  ) => caregiverTreatmentRequest(_store, request, (response) {
    final treatment = TreatmentMapper.treatment(response.body);
    return treatment.id == treatmentId && treatment.status == expected
        ? AppSuccess(treatment)
        : const AppFailure('INVALID_RESPONSE');
  });
}
