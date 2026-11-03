import '../../../../shared/application/session/session_owner.dart';
import '../../../../shared/application/session/session_store.dart';
import '../../../../shared/application/time/clock.dart';
import '../../../../shared/common/result/app_result.dart';
import '../../../../shared/infrastructure/network/api_response.dart';
import '../../application/ports/pin_access.dart';
import '../../domain/entities/account_session.dart';
import '../../domain/value_objects/pin_code.dart';
import '../mappers/session_mapper.dart';
import '../remote/pin_api.dart';
import '../remote/session_dto.dart';

/// Enrolls adult PINs and exchanges them for adult sessions with generation checks.
/// The PIN response lacks careLinkId, so the current-session read completes the
/// owner before anything is persisted.
final class RemotePinAccess implements PinAccess {
  const RemotePinAccess({
    required this._api,
    required this._store,
    required this._clock,
  });

  final PinApi _api;
  final SessionStore _store;
  final Clock _clock;

  @override
  Future<AppResult<void>> register(PinCode pin) => _guard(() async {
    await _store.initialize();
    final session = _store.current;
    if (session == null) return const AppFailure('AUTHENTICATION_REQUIRED');
    if (session.owner.role != SessionRole.olderAdult) {
      return const AppFailure('ACCESS_DENIED');
    }
    final generation = _store.generation;
    final response = await _api.register(
      session.owner.id,
      pin.value,
      session.accessToken,
    );
    if (_store.generation != generation ||
        _store.current?.owner != session.owner) {
      return const AppFailure('SESSION_CHANGED');
    }
    if (response.status == 201) return const AppSuccess(null);
    if (response.status == 401) {
      return await _store.replace(null, expectedGeneration: generation)
          ? const AppFailure('AUTHENTICATION_REQUIRED')
          : const AppFailure('SESSION_CHANGED');
    }
    return _failure(response);
  });

  @override
  Future<AppResult<AccountSession>> signIn(String olderAdultId, PinCode pin) =>
      _guard(() async {
        await _store.initialize();
        final generation = _store.generation;
        final response = await _api.signIn(olderAdultId, pin.value);
        if (_store.generation != generation) {
          return const AppFailure('SESSION_CHANGED');
        }
        if (response.status != 200) return _failure(response);
        final issued = SessionDto.fromJson(response.body);
        if (issued.olderAdultId != olderAdultId || issued.accountId != null) {
          return const AppFailure('INVALID_RESPONSE');
        }
        final current = await _api.current(issued.accessToken);
        if (_store.generation != generation) {
          return const AppFailure('SESSION_CHANGED');
        }
        if (current.status != 200) return _failure(current);
        final body = current.body;
        final careLinkId = body is Map<String, dynamic>
            ? body['careLinkId']
            : null;
        if (body is! Map<String, dynamic> ||
            body['subjectId'] != olderAdultId ||
            body['role'] != 'OLDER_ADULT' ||
            careLinkId is! String) {
          return const AppFailure('INVALID_RESPONSE');
        }
        final session = mapSession(
          SessionDto(
            accountId: null,
            olderAdultId: olderAdultId,
            accessToken: issued.accessToken,
            expiresAt: issued.expiresAt,
            careLinkId: careLinkId,
          ),
          _clock(),
        );
        if (!await _store.replace(session, expectedGeneration: generation)) {
          return const AppFailure('SESSION_CHANGED');
        }
        return AppSuccess(
          AccountSession(owner: session.owner, expiresAt: session.expiresAt),
        );
      });

  Future<AppResult<T>> _guard<T>(Future<AppResult<T>> Function() action) async {
    try {
      return await action();
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

  /// Uses the stable problem title only for the PIN codes the backend documents.
  AppFailure<T> _failure<T>(ApiResponse response) {
    final body = response.body;
    final code = body is Map<String, dynamic> ? body['title'] : null;
    return switch ((response.status, code)) {
      (401, 'INVALID_PIN') => const AppFailure('INVALID_PIN'),
      (403, 'PIN_LOCKED') => const AppFailure('PIN_LOCKED'),
      (404, 'PIN_NOT_FOUND') => const AppFailure('PIN_NOT_FOUND'),
      (409, 'PIN_ALREADY_REGISTERED') => const AppFailure(
        'PIN_ALREADY_REGISTERED',
      ),
      // The backend rejects PIN access with 400 when no confirmed link remains.
      (400, _) => const AppFailure('PIN_ACCESS_UNAVAILABLE'),
      (401, _) => const AppFailure('AUTHENTICATION_REQUIRED'),
      (403, _) => const AppFailure('ACCESS_DENIED'),
      (429, _) => const AppFailure('RATE_LIMITED'),
      _ => const AppFailure('REQUEST_FAILED'),
    };
  }
}
