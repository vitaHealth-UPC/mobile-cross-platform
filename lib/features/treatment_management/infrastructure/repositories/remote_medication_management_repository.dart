import '../../../../shared/application/session/session_store.dart';
import '../../../../shared/application/session/stored_session.dart';
import '../../../../shared/common/result/app_result.dart';
import '../../../../shared/infrastructure/network/api_response.dart';
import '../../domain/entities/medication.dart';
import '../../domain/repositories/treatment_repositories.dart';
import '../mappers/treatment_mapper.dart';
import '../remote/treatment_api.dart';
import 'treatment_requests.dart';

/// Lists, updates, deactivates and reactivates medications, validating every receipt.
final class RemoteMedicationManagementRepository
    implements MedicationManagementRepository {
  const RemoteMedicationManagementRepository({
    required this._api,
    required this._store,
  });
  final TreatmentApi _api;
  final SessionStore _store;

  @override
  Future<AppResult<List<Medication>>> list(String olderAdultId) =>
      caregiverTreatmentRequest(
        _store,
        (session) => _api.listMedications(
          olderAdultId,
          session.owner.id,
          session.accessToken,
        ),
        (response) {
          final items = TreatmentMapper.medications(response.body);
          return items.every((item) => item.olderAdultId == olderAdultId)
              ? AppSuccess(items)
              : const AppFailure('INVALID_RESPONSE');
        },
      );

  @override
  Future<AppResult<Medication>> update(
    String medicationId,
    String name,
    String presentation,
  ) => _change(
    medicationId,
    (session) => _api.updateMedication(
      medicationId,
      session.owner.id,
      name,
      presentation,
      session.accessToken,
    ),
    (medication) =>
        medication.name == name.trim() &&
        medication.presentation == presentation.trim(),
  );

  @override
  Future<AppResult<Medication>> deactivate(String medicationId) => _change(
    medicationId,
    (session) => _api.deactivateMedication(
      medicationId,
      session.owner.id,
      session.accessToken,
    ),
    (medication) => !medication.active,
  );

  @override
  Future<AppResult<Medication>> reactivate(String medicationId) => _change(
    medicationId,
    (session) => _api.reactivateMedication(
      medicationId,
      session.owner.id,
      session.accessToken,
    ),
    (medication) => medication.active,
  );

  Future<AppResult<Medication>> _change(
    String medicationId,
    Future<ApiResponse> Function(StoredSession) request,
    bool Function(Medication) acknowledges,
  ) => caregiverTreatmentRequest(_store, request, (response) {
    final medication = TreatmentMapper.medication(response.body);
    return medication.id == medicationId && acknowledges(medication)
        ? AppSuccess(medication)
        : const AppFailure('INVALID_RESPONSE');
  });
}
