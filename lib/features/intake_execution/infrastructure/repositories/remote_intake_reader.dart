import '../../../../shared/application/session/session_store.dart';
import '../../../../shared/common/result/app_result.dart';
import '../../application/ports/intake_reader.dart';
import '../../domain/entities/intake.dart';
import '../mappers/intake_mapper.dart';
import '../remote/intake_api.dart';
import 'adult_session_request.dart';

/// Reads intakes for the adult of the captured full adult session only.
/// Evidence that belongs to another adult is rejected as an invalid response.
final class RemoteIntakeReader implements IntakeReader {
  const RemoteIntakeReader({required this._api, required this._store});

  final IntakeApi _api;
  final SessionStore _store;

  @override
  Future<AppResult<Intake?>> next() => adultSessionRequest(
    _store,
    (session) => _api.next(session.owner.id, session.accessToken),
    (response, owner) {
      if (response.status == 204) return const AppSuccess(null);
      if (response.status != 200) return const AppFailure('REQUEST_FAILED');
      final intake = IntakeMapper.intake(response.body);
      return intake.olderAdultId == owner.id
          ? AppSuccess(intake)
          : const AppFailure('INVALID_RESPONSE');
    },
  );

  @override
  Future<AppResult<List<Intake>>> agenda(DateTime from, DateTime to) =>
      adultSessionRequest(
        _store,
        (session) =>
            _api.agenda(session.owner.id, from, to, session.accessToken),
        (response, owner) {
          if (response.status != 200) {
            return const AppFailure('REQUEST_FAILED');
          }
          final intakes = IntakeMapper.agenda(response.body);
          return intakes.every((intake) => intake.olderAdultId == owner.id)
              ? AppSuccess(intakes)
              : const AppFailure('INVALID_RESPONSE');
        },
      );

  @override
  Future<AppResult<Intake>> detail(String intakeId) => adultSessionRequest(
    _store,
    (session) => _api.detail(intakeId, session.accessToken),
    (response, owner) {
      if (response.status == 404) return const AppFailure('INTAKE_NOT_FOUND');
      if (response.status != 200) return const AppFailure('REQUEST_FAILED');
      final intake = IntakeMapper.intake(response.body);
      return intake.id == intakeId && intake.olderAdultId == owner.id
          ? AppSuccess(intake)
          : const AppFailure('INVALID_RESPONSE');
    },
  );
}
