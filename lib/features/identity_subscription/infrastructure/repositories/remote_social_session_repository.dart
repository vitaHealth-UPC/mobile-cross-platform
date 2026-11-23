import '../../../../shared/application/session/session_owner.dart';
import '../../../../shared/application/session/session_store.dart';
import '../../../../shared/application/time/clock.dart';
import '../../../../shared/common/result/app_result.dart';
import '../../../../shared/infrastructure/network/api_response.dart';
import '../../application/ports/social_credentials.dart';
import '../../domain/entities/account_session.dart';
import '../../domain/repositories/social_session_repository.dart';
import '../../domain/value_objects/social_provider.dart';
import '../mappers/session_mapper.dart';
import '../mappers/social_failure_mapper.dart';
import '../remote/session_api.dart';
import '../remote/session_dto.dart';

/// Stores only the validated Tata credential returned after Firebase verification.
/// The generation captured before opening the provider prevents late resurrection.
final class RemoteSocialSessionRepository implements SocialSessionRepository {
  const RemoteSocialSessionRepository({
    required this._credentials,
    required this._api,
    required this._store,
    required this._clock,
  });

  final SocialCredentials _credentials;
  final SessionApi _api;
  final SessionStore _store;
  final Clock _clock;

  @override
  Future<AppResult<AccountSession?>> signIn(SocialProvider provider) async {
    try {
      await _store.initialize();
      final generation = _store.generation;
      final evidence = await _credentials.authenticate(provider);
      if (_store.generation != generation) {
        return const AppFailure('SESSION_CHANGED');
      }
      if (evidence case AppFailure<SocialIdentityToken?>(:final code)) {
        return AppFailure(code);
      }
      final token = (evidence as AppSuccess<SocialIdentityToken?>).value;
      if (token == null) return const AppSuccess(null);
      final response = await _api.signInWithFirebase(token.value);
      if (_store.generation != generation) {
        return const AppFailure('SESSION_CHANGED');
      }
      if (response.status != 200) return socialFailure(response);
      final session = mapSession(SessionDto.fromJson(response.body), _clock());
      if (session.owner.role != SessionRole.caregiver) {
        return const AppFailure('INVALID_RESPONSE');
      }
      if (!await _store.replace(session, expectedGeneration: generation)) {
        return const AppFailure('SESSION_CHANGED');
      }
      return AppSuccess(
        AccountSession(owner: session.owner, expiresAt: session.expiresAt),
      );
    } on ApiTransportException catch (error) {
      return AppFailure(error.code);
    } on FormatException {
      return const AppFailure('INVALID_RESPONSE');
    } on ArgumentError {
      return const AppFailure('INVALID_RESPONSE');
    } on Exception {
      return const AppFailure('SOCIAL_AUTHENTICATION_FAILED');
    }
  }
}
