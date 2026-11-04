import '../../../../shared/application/session/session_owner.dart';
import '../../../../shared/application/session/session_store.dart';
import '../../../../shared/application/session/stored_session.dart';
import '../../../../shared/common/result/app_result.dart';
import '../../../../shared/infrastructure/network/api_response.dart';

/// Runs [request] with the captured full adult session and maps its response.
/// Only older-adult sessions may read or change intake evidence; a response
/// that arrives after the session changed is discarded, and 401 clears the
/// rejected credential.
Future<AppResult<T>> adultSessionRequest<T>(
  SessionStore store,
  Future<ApiResponse> Function(StoredSession session) request,
  AppResult<T> Function(ApiResponse response, SessionOwner owner) map,
) async {
  try {
    await store.initialize();
    final session = store.current;
    if (session == null) return const AppFailure('AUTHENTICATION_REQUIRED');
    if (session.owner.role != SessionRole.olderAdult) {
      return const AppFailure('ACCESS_DENIED');
    }
    final generation = store.generation;
    final response = await request(session);
    if (store.generation != generation ||
        store.current?.owner != session.owner) {
      return const AppFailure('SESSION_CHANGED');
    }
    if (response.status == 401) {
      return await store.replace(null, expectedGeneration: generation)
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
