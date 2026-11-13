import '../../../../shared/application/session/session_owner.dart';
import '../../../../shared/application/session/session_store.dart';
import '../../../../shared/application/session/stored_session.dart';
import '../../../../shared/common/result/app_result.dart';
import '../../../../shared/infrastructure/session/authorized_request.dart';
import '../../application/ports/omission_ports.dart';
import '../remote/push_device_api.dart';

/// Registers one installation with the credentials captured for the operation and validates
/// the server receipt. The token is never logged or put in an error.
final class RemoteDeviceTokenRegistry implements DeviceTokenRegistry {
  RemoteDeviceTokenRegistry({
    required this._api,
    required this._store,
    required this.installationId,
  }) {
    if (!_uuid.hasMatch(installationId)) {
      throw ArgumentError('The installation must be identified by a UUID');
    }
  }

  static final _uuid = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
  );
  static const _roles = {SessionRole.caregiver, SessionRole.olderAdult};

  final PushDeviceApi _api;
  final SessionStore _store;
  final String installationId;

  @override
  Future<AppResult<void>> register(
    String token, {
    StoredSession? expectedSession,
  }) async {
    if (token.trim().isEmpty || token.length > 4096) {
      return const AppFailure('INVALID_DEVICE_TOKEN');
    }
    return _withExpected(
      expectedSession,
      () => authorizedRequest<void>(
        _store,
        _roles,
        (session) => _api.register(installationId, token, session.accessToken),
        (response, _) {
          if (response.status == 400) {
            return const AppFailure('INVALID_DEVICE_TOKEN');
          }
          if (response.status < 200 || response.status >= 300) {
            return const AppFailure('REQUEST_FAILED');
          }
          final body = response.body;
          if (body is! Map<String, Object?> ||
              body['installationId'] != installationId ||
              DateTime.tryParse('${body['updatedAt']}') == null) {
            return const AppFailure('INVALID_RESPONSE');
          }
          return const AppSuccess(null);
        },
      ),
    );
  }

  @override
  Future<AppResult<void>> unregister({StoredSession? expectedSession}) =>
      _withExpected(
        expectedSession,
        () => authorizedRequest<void>(
          _store,
          _roles,
          (session) => _api.unregister(installationId, session.accessToken),
          (response, _) => switch (response.status) {
            204 => const AppSuccess(null),
            >= 200 && < 300 => const AppFailure('INVALID_RESPONSE'),
            _ => const AppFailure('REQUEST_FAILED'),
          },
        ),
      );

  /// A request meant for one session is not sent under another one.
  Future<AppResult<void>> _withExpected(
    StoredSession? expected,
    Future<AppResult<void>> Function() send,
  ) async {
    if (expected != null) {
      await _store.initialize();
      final current = _store.current;
      if (current == null ||
          current.owner != expected.owner ||
          current.accessToken != expected.accessToken) {
        return const AppFailure('SESSION_CHANGED');
      }
    }
    return send();
  }
}
