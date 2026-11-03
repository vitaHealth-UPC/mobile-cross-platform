import '../../../../shared/application/session/session_owner.dart';
import '../../../../shared/application/session/session_store.dart';
import '../../../../shared/common/result/app_result.dart';
import '../../../../shared/infrastructure/network/api_response.dart';
import '../../application/ports/adult_profile_reader.dart';
import '../../application/readmodels/older_adult_profile.dart';
import '../mappers/care_link_mapper.dart';
import '../remote/care_link_api.dart';

/// Reads the adult's own profile; a profile for another adult is rejected.
final class RemoteAdultProfileReader implements AdultProfileReader {
  const RemoteAdultProfileReader({required this._api, required this._store});

  final CareLinkApi _api;
  final SessionStore _store;

  @override
  Future<AppResult<OlderAdultProfile>> readOwn() async {
    try {
      await _store.initialize();
      final session = _store.current;
      if (session == null) return const AppFailure('AUTHENTICATION_REQUIRED');
      if (session.owner.role != SessionRole.olderAdult) {
        return const AppFailure('ACCESS_DENIED');
      }
      final generation = _store.generation;
      final response = await _api.profile(
        session.owner.id,
        session.accessToken,
      );
      if (_store.generation != generation) {
        return const AppFailure('SESSION_CHANGED');
      }
      if (response.status == 401) {
        return const AppFailure('AUTHENTICATION_REQUIRED');
      }
      if (response.status == 403) return const AppFailure('ACCESS_DENIED');
      if (response.status != 200) {
        return const AppFailure('CARE_LINK_REQUEST_FAILED');
      }
      final profile = CareLinkMapper.profile(response.body);
      return profile.id == session.owner.id
          ? AppSuccess(profile)
          : const AppFailure('INVALID_RESPONSE');
    } on ApiTransportException catch (error) {
      return AppFailure(error.code);
    } on FormatException {
      return const AppFailure('INVALID_RESPONSE');
    } on Exception {
      return const AppFailure('SESSION_STORAGE_UNAVAILABLE');
    }
  }
}
