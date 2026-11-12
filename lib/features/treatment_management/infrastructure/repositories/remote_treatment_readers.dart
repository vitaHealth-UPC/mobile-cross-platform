import '../../../../shared/application/session/session_owner.dart';
import '../../../../shared/application/session/session_store.dart';
import '../../../../shared/common/result/app_result.dart';
import '../../../../shared/infrastructure/session/authorized_request.dart';
import '../../application/ports/treatment_readers.dart';
import '../../application/readmodels/treatment_readmodels.dart';
import '../mappers/treatment_mapper.dart';
import '../remote/treatment_api.dart';
import 'treatment_requests.dart';

/// Reads treatments for the captured caregiver, rejecting evidence of another adult.
final class RemoteTreatmentReader implements TreatmentReader {
  const RemoteTreatmentReader({required this._api, required this._store});
  final TreatmentApi _api;
  final SessionStore _store;

  @override
  Future<AppResult<List<TreatmentDetail>>> list(String olderAdultId) =>
      caregiverTreatmentRequest(
        _store,
        (session) => _api.listTreatments(
          olderAdultId,
          session.owner.id,
          session.accessToken,
        ),
        (response) {
          final items = TreatmentMapper.details(response.body);
          return items.every((item) => item.olderAdultId == olderAdultId)
              ? AppSuccess(items)
              : const AppFailure('INVALID_RESPONSE');
        },
      );

  @override
  Future<AppResult<TreatmentDetail>> detail(String treatmentId) =>
      caregiverTreatmentRequest(
        _store,
        (session) => _api.treatmentDetail(
          treatmentId,
          session.owner.id,
          session.accessToken,
        ),
        (response) {
          final detail = TreatmentMapper.detail(response.body);
          return detail.id == treatmentId
              ? AppSuccess(detail)
              : const AppFailure('INVALID_RESPONSE');
        },
      );
}

/// Reads the catalog of the full older-adult session only.
final class RemoteMyMedicationsReader implements MyMedicationsReader {
  const RemoteMyMedicationsReader({required this._api, required this._store});
  final TreatmentApi _api;
  final SessionStore _store;

  @override
  Future<AppResult<List<MyMedication>>> list() => authorizedRequest(
    _store,
    const {SessionRole.olderAdult},
    (session) => _api.myMedications(session.accessToken),
    (response, owner) => response.status == 200
        ? AppSuccess(
            TreatmentMapper.myMedications(response.body, ownerId: owner.id),
          )
        : const AppFailure('REQUEST_FAILED'),
  );
}
