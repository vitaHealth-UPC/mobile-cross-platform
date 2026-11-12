import '../../../../shared/application/session/session_store.dart';
import '../../../../shared/common/result/app_result.dart';
import '../../domain/entities/medication.dart';
import '../../domain/entities/treatment.dart';
import '../../domain/repositories/treatment_repositories.dart';
import '../mappers/treatment_mapper.dart';
import '../remote/treatment_api.dart';
import 'treatment_requests.dart';

/// Registers medications and creates treatment drafts, validating every receipt.
final class RemoteTreatmentRepository implements TreatmentRepository {
  const RemoteTreatmentRepository({required this._api, required this._store});
  final TreatmentApi _api;
  final SessionStore _store;

  @override
  Future<AppResult<Medication>> registerMedication(
    String olderAdultId,
    String name,
    String presentation,
  ) => caregiverTreatmentRequest(
    _store,
    (session) => _api.registerMedication(
      olderAdultId,
      session.owner.id,
      name,
      presentation,
      session.accessToken,
    ),
    (response) {
      final medication = TreatmentMapper.medication(response.body);
      if (medication.olderAdultId != olderAdultId ||
          medication.name != name.trim() ||
          medication.presentation != presentation.trim()) {
        return const AppFailure('INVALID_RESPONSE');
      }
      return AppSuccess(medication);
    },
  );

  @override
  Future<AppResult<Treatment>> createTreatment(
    String olderAdultId,
    String name,
  ) => caregiverTreatmentRequest(
    _store,
    (session) => _api.createTreatment(
      olderAdultId,
      session.owner.id,
      name,
      session.accessToken,
    ),
    (response) {
      final treatment = TreatmentMapper.treatment(response.body);
      if (treatment.olderAdultId != olderAdultId ||
          treatment.name != name.trim()) {
        return const AppFailure('INVALID_RESPONSE');
      }
      return AppSuccess(treatment);
    },
  );
}
