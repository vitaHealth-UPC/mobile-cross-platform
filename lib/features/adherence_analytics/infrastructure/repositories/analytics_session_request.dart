import '../../../../shared/application/session/session_owner.dart';
import '../../../../shared/application/session/session_store.dart';
import '../../../../shared/application/session/stored_session.dart';
import '../../../../shared/common/result/app_result.dart';
import '../../../../shared/infrastructure/network/api_response.dart';

/// Runs [request] with the captured session of a caregiver or an older adult
/// and maps its response.
///
/// A caregiver reads the adult of the link they selected; the server verifies
/// the consent. An adult may only read their own evidence. A session that
/// changes while the request is in flight discards the response, 401 clears
/// the rejected credential and 403 (including withdrawn consent) is
/// `ACCESS_DENIED`. Setup sessions never read adherence.
Future<AppResult<T>> analyticsSessionRequest<T>(
  SessionStore store,
  String olderAdultId,
  Future<ApiResponse> Function(StoredSession session) request,
  AppResult<T> Function(ApiResponse response) map,
) async {
  try {
    await store.initialize();
    final session = store.current;
    if (session == null) return const AppFailure('AUTHENTICATION_REQUIRED');
    final owner = session.owner;
    if (owner.role == SessionRole.linkSetup ||
        (owner.role == SessionRole.olderAdult && owner.id != olderAdultId)) {
      return const AppFailure('ACCESS_DENIED');
    }
    final generation = store.generation;
    final response = await request(session);
    if (store.generation != generation || store.current?.owner != owner) {
      return const AppFailure('SESSION_CHANGED');
    }
    if (response.status == 401) {
      return await store.replace(null, expectedGeneration: generation)
          ? const AppFailure('AUTHENTICATION_REQUIRED')
          : const AppFailure('SESSION_CHANGED');
    }
    if (response.status == 403) return const AppFailure('ACCESS_DENIED');
    if (response.status == 429) return const AppFailure('RATE_LIMITED');
    return map(response);
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
