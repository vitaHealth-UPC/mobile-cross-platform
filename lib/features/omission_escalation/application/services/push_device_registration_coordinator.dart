import 'dart:async';

import '../../../../shared/application/session/session_owner.dart';
import '../../../../shared/application/session/session_store.dart';
import '../../../../shared/application/session/stored_session.dart';
import '../../../../shared/application/time/clock.dart';
import '../../../../shared/common/result/app_result.dart';
import '../ports/omission_ports.dart';

/// Serializes installation updates across login, SDK token rotation and authenticated
/// logout.
///
/// The host calls [synchronize] when a signed-in screen appears (login recovers a token
/// issued before it), [onNewToken] when the SDK rotates the token and [beforeSignOut]
/// before the credential is discarded.
final class PushDeviceRegistrationCoordinator {
  PushDeviceRegistrationCoordinator({
    required this._sessions,
    required this._tokens,
    required this._registry,
    Clock? now,
    this.retryDelays = const [
      Duration(seconds: 5),
      Duration(seconds: 15),
      Duration(seconds: 60),
    ],
    this.tokenTimeout = const Duration(seconds: 10),
    this.unregisterTimeout = const Duration(seconds: 5),
    Future<void> Function(Duration)? wait,
  }) : _now = now ?? DateTime.now,
       _wait = wait ?? Future<void>.delayed;

  final SessionStore _sessions;
  final DevicePushTokenSource _tokens;
  final DeviceTokenRegistry _registry;
  final Clock _now;
  final Future<void> Function(Duration) _wait;
  final List<Duration> retryDelays;
  final Duration tokenTimeout;
  final Duration unregisterTimeout;

  static const _retryable = {
    'NETWORK_UNAVAILABLE',
    'REQUEST_FAILED',
    'PUSH_TOKEN_UNAVAILABLE',
  };

  Future<void> _tail = Future<void>.value();
  String? _latestToken;
  String? _signingOutToken;
  bool _registrationAttempted = false;
  int _run = 0;

  /// Registers this installation for the session in force; a later call supersedes the
  /// retries of an earlier one.
  Future<void> synchronize() async {
    await _sessions.initialize();
    final run = ++_run;
    final captured = _sessions.current;
    if (captured == null || !_usable(captured)) return;
    var attempt = 0;
    while (run == _run && _current(captured)) {
      final retry = await _synchronizeOnce(captured);
      if (!retry || attempt >= retryDelays.length) return;
      await _wait(retryDelays[attempt++]);
    }
  }

  /// Keeps SDK callbacks independent of any screen: the new token is registered at once.
  Future<void> onNewToken(String token) async {
    await _serial(() async => _latestToken = token);
    await synchronize();
  }

  /// Bounds best-effort remote removal so an unavailable transport cannot trap sign-out.
  Future<void> beforeSignOut() async {
    await _sessions.initialize();
    final captured = _sessions.current;
    if (captured == null) return;
    _signingOutToken = captured.accessToken;
    if (!_registrationAttempted) return;
    try {
      await _serial(() => _registry.unregister(expectedSession: captured))
          .timeout(unregisterTimeout);
    } on TimeoutException {
      // The server drops stale installations; sign-out must not wait for it.
    }
  }

  /// Releases the mutation lock before backoff so logout and rotation stay responsive.
  Future<bool> _synchronizeOnce(StoredSession captured) => _serial(() async {
    if (!_current(captured)) return false;
    var token = _latestToken;
    if (token == null) {
      final AppResult<String?> result;
      try {
        result = await _tokens.currentToken().timeout(tokenTimeout);
      } on TimeoutException {
        return true;
      }
      switch (result) {
        case AppFailure(:final code):
          return _retryable.contains(code);
        case AppSuccess(:final value):
          token = value;
      }
    }
    if (token == null) return false;
    if (!_current(captured)) return false;
    _registrationAttempted = true;
    final result = await _registry.register(token, expectedSession: captured);
    return result is AppFailure<void> && _retryable.contains(result.code);
  });

  bool _current(StoredSession captured) {
    final current = _sessions.current;
    return current != null &&
        _usable(current) &&
        current.owner == captured.owner &&
        current.accessToken == captured.accessToken &&
        _signingOutToken != captured.accessToken;
  }

  bool _usable(StoredSession session) =>
      session.owner.role != SessionRole.linkSetup && session.isValidAt(_now());

  Future<T> _serial<T>(Future<T> Function() operation) {
    final result = _tail.then((_) => operation());
    _tail = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }
}
