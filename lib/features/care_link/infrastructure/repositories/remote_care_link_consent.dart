import '../../../../shared/application/session/session_owner.dart';
import '../../../../shared/application/session/session_store.dart';
import '../../../../shared/application/session/stored_session.dart';
import '../../../../shared/application/time/clock.dart';
import '../../../../shared/common/result/app_result.dart';
import '../../../../shared/infrastructure/network/api_response.dart';
import '../../application/ports/care_link_consent.dart';
import '../../domain/entities/care_link.dart';
import '../../domain/value_objects/care_link_invitation.dart';
import '../mappers/care_link_mapper.dart';
import '../remote/care_link_api.dart';

/// Handles anonymous invitation exchange and relationship-scoped consent.
/// Restricted credentials persist securely but never masquerade as full adult access.
final class RemoteCareLinkConsent implements CareLinkConsent {
  const RemoteCareLinkConsent({
    required this._api,
    required this._store,
    required this._clock,
  });
  final CareLinkApi _api;
  final SessionStore _store;
  final Clock _clock;

  @override
  Future<AppResult<CareLink>> accept(CareLinkInvitation invitation) =>
      _guard(() async {
        await _store.initialize();
        if (_store.current != null) return const AppFailure('ACCESS_DENIED');
        final generation = _store.generation;
        final response = await _api.accept(
          invitation.caregiverId,
          invitation.code,
        );
        if (_store.generation != generation) {
          return const AppFailure('SESSION_CHANGED');
        }
        if (response.status != 200) return _failure(response);
        final link = CareLinkMapper.awaiting(response.body);
        if (link.caregiverId != invitation.caregiverId) {
          return const AppFailure('INVALID_RESPONSE');
        }
        final credential = CareLinkMapper.issued(
          response.body,
          link,
          SessionRole.linkSetup,
          _clock(),
        );
        if (!await _store.replace(credential, expectedGeneration: generation)) {
          return const AppFailure('SESSION_CHANGED');
        }
        return AppSuccess(link);
      });

  @override
  Future<AppResult<CareLink>> pending() => _restricted(
    (session) => _api.link(session.owner.careLinkId!, session.accessToken),
    null,
  );

  @override
  Future<AppResult<CareLink>> decide(bool accepted) => _restricted(
    (session) =>
        _api.consent(session.owner.careLinkId!, accepted, session.accessToken),
    accepted,
  );

  Future<AppResult<CareLink>> _restricted(
    Future<ApiResponse> Function(StoredSession) action,
    bool? decision,
  ) => _guard(() async {
    await _store.initialize();
    final session = _store.current;
    if (session == null) return const AppFailure('AUTHENTICATION_REQUIRED');
    if (session.owner.role != SessionRole.linkSetup) {
      return const AppFailure('ACCESS_DENIED');
    }
    final generation = _store.generation;
    final response = await action(session);
    if (_store.generation != generation ||
        _store.current?.owner != session.owner) {
      return const AppFailure('SESSION_CHANGED');
    }
    if (response.status == 401) {
      if (!await _store.replace(null, expectedGeneration: generation)) {
        return const AppFailure('SESSION_CHANGED');
      }
      return const AppFailure('AUTHENTICATION_REQUIRED');
    }
    if (response.status != 200) return _failure(response);
    final link = decision == null
        ? CareLinkMapper.awaiting(response.body)
        : CareLinkMapper.decided(response.body, decision);
    if (link.id != session.owner.careLinkId ||
        link.olderAdultId != session.owner.id) {
      return const AppFailure('INVALID_RESPONSE');
    }
    if (decision != null) {
      final credential = decision
          ? CareLinkMapper.issued(
              response.body,
              link,
              SessionRole.olderAdult,
              _clock(),
            )
          : null;
      if (!await _store.replace(credential, expectedGeneration: generation)) {
        return const AppFailure('SESSION_CHANGED');
      }
    }
    return AppSuccess(link);
  });

  @override
  Future<AppResult<void>> withdraw() => _guard(() async {
    await _store.initialize();
    final session = _store.current;
    if (session == null) return const AppFailure('AUTHENTICATION_REQUIRED');
    if (session.owner.role != SessionRole.olderAdult) {
      return const AppFailure('ACCESS_DENIED');
    }
    final generation = _store.generation;
    final response = await _api.withdraw(
      session.owner.careLinkId!,
      session.accessToken,
    );
    if (_store.generation != generation ||
        _store.current?.owner != session.owner) {
      return const AppFailure('SESSION_CHANGED');
    }
    if (response.status == 204 || response.status == 401) {
      if (!await _store.replace(null, expectedGeneration: generation)) {
        return const AppFailure('SESSION_CHANGED');
      }
      return response.status == 204
          ? const AppSuccess(null)
          : const AppFailure('AUTHENTICATION_REQUIRED');
    }
    return _failure(response);
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

  AppFailure<T> _failure<T>(ApiResponse response) {
    if (response.status == 400) return const AppFailure('INVALID_LINKING_CODE');
    if (response.status == 410) {
      return const AppFailure('LINKING_CODE_EXPIRED_OR_USED');
    }
    if (response.status == 403) return const AppFailure('ACCESS_DENIED');
    if (response.status == 429) return const AppFailure('RATE_LIMITED');
    return const AppFailure('CARE_LINK_REQUEST_FAILED');
  }
}
