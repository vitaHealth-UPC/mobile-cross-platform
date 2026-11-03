import '../../../../shared/application/session/session_owner.dart';
import '../../../../shared/application/session/session_store.dart';
import '../../../../shared/application/session/stored_session.dart';
import '../../../../shared/application/time/clock.dart';
import '../../../../shared/common/result/app_result.dart';
import '../../../../shared/infrastructure/network/api_response.dart';
import '../../application/ports/care_link_writer.dart';
import '../../application/ports/caregiver_profiles_reader.dart';
import '../../application/readmodels/caregiver_link_summary.dart';
import '../../application/readmodels/older_adult_profile.dart';
import '../../domain/entities/care_link.dart';
import '../mappers/care_link_mapper.dart';
import '../remote/care_link_api.dart';

/// Captures caregiver identity for each request and rejects results after actor changes.
/// Profile registration and code issuance never replace or issue an adult session.
final class RemoteCareLinkRepository
    implements CareLinkWriter, CaregiverProfilesReader {
  const RemoteCareLinkRepository({
    required this._api,
    required this._store,
    required this._clock,
  });
  final CareLinkApi _api;
  final SessionStore _store;
  final Clock _clock;

  @override
  Future<AppResult<List<CaregiverLinkSummary>>> readConfirmed() =>
      _authorized((session) async {
        final response = await _api.confirmed(
          session.owner.id,
          session.accessToken,
        );
        if (response.status != 200) return _failure(response);
        return AppSuccess(CareLinkMapper.confirmed(response.body));
      });

  @override
  Future<AppResult<OlderAdultProfile>> registerOlderAdult(
    String fullName,
    DateTime birthDate,
  ) => _authorized((session) async {
    final response = await _api.register(
      session.owner.id,
      fullName,
      birthDate,
      session.accessToken,
    );
    if (response.status != 201) return _failure(response);
    final profile = CareLinkMapper.profile(response.body);
    if (profile.caregiverId != session.owner.id ||
        profile.fullName != fullName ||
        profile.birthDate != birthDate) {
      return const AppFailure('INVALID_RESPONSE');
    }
    return AppSuccess(profile);
  });

  @override
  Future<AppResult<CareLink>> generateCode(String olderAdultId) =>
      _authorized((session) async {
        final response = await _api.generate(
          session.owner.id,
          olderAdultId,
          session.accessToken,
        );
        if (response.status != 201) return _failure(response);
        final link = CareLinkMapper.pending(response.body);
        if (link.caregiverId != session.owner.id ||
            link.olderAdultId != olderAdultId ||
            !link.code!.isValidAt(_clock())) {
          return const AppFailure('INVALID_RESPONSE');
        }
        return AppSuccess(link);
      });

  Future<AppResult<T>> _authorized<T>(
    Future<AppResult<T>> Function(StoredSession) action,
  ) async {
    try {
      await _store.initialize();
      final session = _store.current;
      if (session == null) return const AppFailure('AUTHENTICATION_REQUIRED');
      if (session.owner.role != SessionRole.caregiver) {
        return const AppFailure('ACCESS_DENIED');
      }
      final generation = _store.generation;
      final result = await action(session);
      if (_store.generation != generation ||
          _store.current?.accessToken != session.accessToken) {
        return const AppFailure('SESSION_CHANGED');
      }
      if (result is AppFailure<T> && result.code == 'AUTHENTICATION_REQUIRED') {
        if (!await _store.replace(null, expectedGeneration: generation)) {
          return const AppFailure('SESSION_CHANGED');
        }
      }
      return result;
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

  AppFailure<T> _failure<T>(ApiResponse response) {
    if (response.status == 401) {
      return const AppFailure('AUTHENTICATION_REQUIRED');
    }
    if (response.status == 403) return const AppFailure('ACCESS_DENIED');
    if (response.status == 429) return const AppFailure('RATE_LIMITED');
    if (response.status == 409) {
      return const AppFailure('CARE_LINK_ALREADY_EXISTS');
    }
    return const AppFailure('CARE_LINK_REQUEST_FAILED');
  }
}
