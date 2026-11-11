import '../../../../shared/application/session/session_owner.dart';
import '../../../../shared/application/session/session_store.dart';
import '../../../../shared/application/session/stored_session.dart';
import '../../../../shared/application/time/clock.dart';
import '../../../../shared/common/result/app_result.dart';
import '../../../../shared/infrastructure/network/api_response.dart';
import '../../domain/entities/account_session.dart';
import '../../domain/repositories/session_repository.dart';
import '../mappers/identity_failure_mapper.dart';
import '../mappers/session_mapper.dart';
import '../remote/session_api.dart';
import '../remote/session_dto.dart';

/// Validates remote identity and coordinates session storage with generation checks.
/// Cached metadata never authenticates a failed restore request, except an
/// older adult with no network, who only reaches data stored for that adult.
final class RemoteSessionRepository implements SessionRepository {
  const RemoteSessionRepository({
    required this._api,
    required this._store,
    required this._clock,
  });

  final SessionApi _api;
  final SessionStore _store;
  final Clock _clock;

  @override
  Future<AppResult<AccountSession>> signIn(
    String email,
    String password,
  ) async {
    try {
      await _store.initialize();
      final generation = _store.generation;
      final response = await _api.signIn(email, password);
      if (_store.generation != generation) {
        return const AppFailure('SESSION_CHANGED');
      }
      if (response.status != 200) return identityFailure(response);
      final session = mapSession(SessionDto.fromJson(response.body), _clock());
      if (!await _store.replace(session, expectedGeneration: generation)) {
        return const AppFailure('SESSION_CHANGED');
      }
      return AppSuccess(_metadata(session));
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

  @override
  Future<AppResult<AccountSession?>> restore() async {
    try {
      await _store.initialize();
      final generation = _store.generation;
      final session = _store.current;
      if (session == null) {
        return await _store.replace(null, expectedGeneration: generation)
            ? const AppSuccess(null)
            : const AppFailure('SESSION_CHANGED');
      }
      final response = await _api.current(session.accessToken);
      if (_store.generation != generation) {
        return const AppFailure('SESSION_CHANGED');
      }
      if (response.status == 401 || response.status == 403) {
        return await _store.replace(null, expectedGeneration: generation)
            ? const AppSuccess(null)
            : const AppFailure('SESSION_CHANGED');
      }
      if (response.status != 200) return identityFailure(response);
      final body = response.body;
      final expectedRole = switch (session.owner.role) {
        SessionRole.caregiver => 'CAREGIVER',
        SessionRole.olderAdult => 'OLDER_ADULT',
        SessionRole.linkSetup => 'LINK_SETUP',
      };
      if (body is! Map<String, dynamic> ||
          body['subjectId'] != session.owner.id ||
          body['role'] != expectedRole ||
          body['careLinkId'] != session.owner.careLinkId) {
        return await _store.replace(null, expectedGeneration: generation)
            ? const AppFailure('INVALID_RESPONSE')
            : const AppFailure('SESSION_CHANGED');
      }
      if (!session.isValidAt(_clock())) {
        return await _store.replace(null, expectedGeneration: generation)
            ? const AppSuccess(null)
            : const AppFailure('SESSION_CHANGED');
      }
      return AppSuccess(_metadata(session));
    } on ApiTransportException catch (error) {
      final session = _store.current;
      // An adult without signal still reaches this device's own doses; every
      // server request keeps validating the credential.
      if (error.code == 'NETWORK_UNAVAILABLE' &&
          session != null &&
          session.owner.role == SessionRole.olderAdult &&
          session.isValidAt(_clock())) {
        return AppSuccess(_metadata(session));
      }
      return AppFailure(error.code);
    } on Exception {
      return const AppFailure('SESSION_STORAGE_UNAVAILABLE');
    }
  }

  @override
  Future<AppResult<void>> signOut() async {
    try {
      await _store.initialize();
      final session = _store.current;
      var storageFailed = false;
      try {
        if (!await _store.replace(
          null,
          expectedGeneration: _store.generation,
        )) {
          return const AppFailure('SESSION_CHANGED');
        }
      } on Exception {
        // Still revoke the captured credential when the device cannot delete it.
        storageFailed = true;
      }
      if (session == null) {
        return storageFailed
            ? const AppFailure('SESSION_STORAGE_UNAVAILABLE')
            : const AppSuccess(null);
      }
      final response = await _api.signOut(session.accessToken);
      if (storageFailed) {
        return const AppFailure('SESSION_STORAGE_UNAVAILABLE');
      }
      if (response.status == 204 || response.status == 401) {
        return const AppSuccess(null);
      }
      return identityFailure(response);
    } on ApiTransportException catch (error) {
      return AppFailure(error.code);
    } on Exception {
      return const AppFailure('SESSION_STORAGE_UNAVAILABLE');
    }
  }

  AccountSession _metadata(StoredSession session) =>
      AccountSession(owner: session.owner, expiresAt: session.expiresAt);
}
