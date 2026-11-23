import '../../application/session/session_owner.dart';
import '../../application/session/session_store.dart';
import '../../application/session/stored_session.dart';
import '../../common/result/app_result.dart';
import '../network/api_response.dart';

/// Runs [request] with the captured session of one of the [roles] and maps its response.
///
/// The credential and actor are captured before the request; a response that arrives
/// after the session changed is discarded. A 401 clears only the rejected credential,
/// 403 means the relationship no longer grants access and 429 asks to retry later.
/// Statuses that are specific to a context are left to [map].
Future<AppResult<T>> authorizedRequest<T>(
  SessionStore store,
  Set<SessionRole> roles,
  Future<ApiResponse> Function(StoredSession session) request,
  AppResult<T> Function(ApiResponse response, SessionOwner owner) map,
) async {
  try {
    await store.initialize();
    final session = store.current;
    if (session == null) return const AppFailure('AUTHENTICATION_REQUIRED');
    if (!roles.contains(session.owner.role)) {
      return const AppFailure('ACCESS_DENIED');
    }
    final generation = store.generation;
    final response = await request(session);
    if (store.generation != generation ||
        store.current?.owner != session.owner ||
        store.current?.accessToken != session.accessToken) {
      return const AppFailure('SESSION_CHANGED');
    }
    if (response.status == 401) {
      return await store.replace(null, expectedGeneration: generation)
          ? const AppFailure('AUTHENTICATION_REQUIRED')
          : const AppFailure('SESSION_CHANGED');
    }
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
