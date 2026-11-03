import '../../../../shared/application/session/session_store.dart';
import '../../../../shared/application/time/clock.dart';
import '../../../../shared/common/result/app_result.dart';
import '../../../../shared/infrastructure/network/api_response.dart';
import '../../application/ports/account_registration.dart';
import '../../domain/entities/account_session.dart';
import '../mappers/identity_failure_mapper.dart';
import '../mappers/session_mapper.dart';
import '../remote/registration_api.dart';
import '../remote/registration_dto.dart';

/// Maps account receipts and persists only a verified, matching issued session.
/// Conditional writes reject responses superseded by another session mutation.
final class RemoteAccountRegistration implements AccountRegistration {
  const RemoteAccountRegistration({
    required this._api,
    required this._store,
    required this._clock,
  });
  final RegistrationApi _api;
  final SessionStore _store;
  final Clock _clock;

  @override
  Future<AppResult<String>> register(
    String name,
    String email,
    String password,
  ) async {
    try {
      final response = await _api.register(name, email, password);
      if (response.status != 201) return identityFailure(response);
      final account = RegistrationDto.fromJson(response.body, verified: false);
      if (account.email != email) return const AppFailure('INVALID_RESPONSE');
      return AppSuccess(account.id);
    } on ApiTransportException catch (error) {
      return AppFailure(error.code);
    } on FormatException {
      return const AppFailure('INVALID_RESPONSE');
    }
  }

  @override
  Future<AppResult<AccountSession>> verify(
    String accountId,
    String email,
    String code,
  ) async {
    try {
      await _store.initialize();
      final generation = _store.generation;
      if (_store.current != null) return const AppFailure('SESSION_CHANGED');
      final response = await _api.verify(email, code);
      if (_store.generation != generation) {
        return const AppFailure('SESSION_CHANGED');
      }
      if (response.status != 200) return identityFailure(response);
      final account = RegistrationDto.fromJson(response.body, verified: true);
      if (account.id != accountId || account.email != email) {
        return const AppFailure('INVALID_RESPONSE');
      }
      final session = mapSession(account.session!, _clock());
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
      return const AppFailure('SESSION_STORAGE_UNAVAILABLE');
    }
  }

  @override
  Future<AppResult<void>> requestVerification(
    String accountId,
    String email,
  ) async {
    try {
      final response = await _api.requestVerification(email);
      if (response.status != 202) return identityFailure(response);
      final account = RegistrationDto.fromJson(response.body, verified: false);
      return account.id == accountId && account.email == email
          ? const AppSuccess(null)
          : const AppFailure('INVALID_RESPONSE');
    } on ApiTransportException catch (error) {
      return AppFailure(error.code);
    } on FormatException {
      return const AppFailure('INVALID_RESPONSE');
    }
  }
}
