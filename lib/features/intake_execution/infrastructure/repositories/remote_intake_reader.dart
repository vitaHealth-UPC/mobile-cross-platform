import '../../../../shared/application/session/session_owner.dart';
import '../../../../shared/application/session/session_store.dart';
import '../../../../shared/application/session/stored_session.dart';
import '../../../../shared/common/result/app_result.dart';
import '../../../../shared/infrastructure/network/api_response.dart';
import '../../application/ports/intake_reader.dart';
import '../../domain/entities/intake.dart';
import '../mappers/intake_mapper.dart';
import '../remote/intake_api.dart';

/// Reads intakes for the adult of the captured full adult session only.
/// A response that arrives after the session changed is discarded.
final class RemoteIntakeReader implements IntakeReader {
  const RemoteIntakeReader({required this._api, required this._store});

  final IntakeApi _api;
  final SessionStore _store;

  @override
  Future<AppResult<Intake?>> next() => _read(
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
  Future<AppResult<List<Intake>>> agenda(DateTime from, DateTime to) => _read(
    (session) => _api.agenda(session.owner.id, from, to, session.accessToken),
    (response, owner) {
      if (response.status != 200) return const AppFailure('REQUEST_FAILED');
      final intakes = IntakeMapper.agenda(response.body);
      return intakes.every((intake) => intake.olderAdultId == owner.id)
          ? AppSuccess(intakes)
          : const AppFailure('INVALID_RESPONSE');
    },
  );

  Future<AppResult<T>> _read<T>(
    Future<ApiResponse> Function(StoredSession session) request,
    AppResult<T> Function(ApiResponse response, SessionOwner owner) map,
  ) async {
    try {
      await _store.initialize();
      final session = _store.current;
      if (session == null) return const AppFailure('AUTHENTICATION_REQUIRED');
      if (session.owner.role != SessionRole.olderAdult) {
        return const AppFailure('ACCESS_DENIED');
      }
      final generation = _store.generation;
      final response = await request(session);
      if (_store.generation != generation ||
          _store.current?.owner != session.owner) {
        return const AppFailure('SESSION_CHANGED');
      }
      if (response.status == 401) {
        return await _store.replace(null, expectedGeneration: generation)
            ? const AppFailure('AUTHENTICATION_REQUIRED')
            : const AppFailure('SESSION_CHANGED');
      }
      // Consent withdrawn by either side removes clinical access.
      if (response.status == 403) return const AppFailure('ACCESS_DENIED');
      if (response.status == 429) return const AppFailure('RATE_LIMITED');
      return map(response, session.owner);
    } on ApiTransportException catch (error) {
      return AppFailure(error.code);
    } on FormatException {
      return const AppFailure('INVALID_RESPONSE');
    } on ArgumentError {
      return const AppFailure('INVALID_RESPONSE');
    } on Exception {
      return const AppFailure('SESSION_STORAGE_UNAVAILABLE');
    }
  }
}
