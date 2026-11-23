import 'dart:async';

import '../../../../shared/application/session/session_owner.dart';
import '../../../../shared/application/session/session_store.dart';
import '../ports/omission_message_source.dart';
import '../readmodels/omission_push_payload.dart';
import '../readmodels/push_destination.dart';
import 'omission_push_facade.dart';

/// Connects transport events to recipient policy and authenticated navigation evidence.
/// The host decides when navigation is ready and owns the actual screen transition.
final class OmissionDeliveryCoordinator {
  OmissionDeliveryCoordinator({
    required this._source,
    required this._facade,
    required this._sessions,
    required this._rotatedTokens,
    required this._localTaps,
    this.initialLocalPayload,
  });

  final OmissionMessageSource _source;
  final OmissionPushFacade _facade;
  final SessionStore _sessions;
  final Stream<String> _rotatedTokens;
  final Stream<String> _localTaps;

  /// Launch evidence from the native notification plugin, including offline startup.
  final Future<String?> Function()? initialLocalPayload;
  final _destinations = StreamController<PushDestination>.broadcast();
  final _subscriptions = <StreamSubscription<dynamic>>[];
  Future<bool>? _starting;
  SessionOwner? _owner;
  String? _pendingPayload;
  bool _canNavigate = false;
  bool _transportReady = false;
  bool _disposed = false;
  int _revision = 0;

  Stream<PushDestination> get destinations => _destinations.stream;

  /// Starts once. SDK configuration failure does not disable local tap authorization.
  Future<bool> start() => _starting ??= _start();

  Future<bool> _start() async {
    if (_disposed) return false;
    _subscriptions.add(
      _localTaps.listen(
        (payload) => unawaited(_protect(() => _open(payload))),
        onError: _ignoreTransportError,
      ),
    );
    final localInitial = await initialLocalPayload?.call();
    if (localInitial != null && !_disposed) await _open(localInitial);
    final available = await _source.initialize();
    if (!available || _disposed) return false;
    _transportReady = true;
    _subscriptions.addAll([
      _source.received.listen(
        (push) => unawaited(
          _protect(() async {
            await _facade.onPush(push);
          }),
        ),
        onError: _ignoreTransportError,
      ),
      _source.opened.listen(
        (payload) => unawaited(_protect(() => _open(payload))),
        onError: _ignoreTransportError,
      ),
      _rotatedTokens.listen(
        (token) => unawaited(_protect(() => _facade.onNewToken(token))),
        onError: _ignoreTransportError,
      ),
    ]);
    final initial = await _source.initialPayload();
    if (initial != null && !_disposed) await _open(initial);
    if (_canNavigate && !_disposed) {
      unawaited(_protect(_facade.synchronizeDevice));
    }
    return !_disposed;
  }

  /// Called after access restoration, sign-in, session refresh or invalidation.
  Future<void> sessionChanged({required bool authenticated}) async {
    final revision = ++_revision;
    await _sessions.initialize();
    if (_disposed || revision != _revision) return;
    final current = _sessions.current;
    if (_owner != null && _owner != current?.owner) _pendingPayload = null;
    _owner = current?.owner;
    _canNavigate = authenticated && current != null;
    await _facade.observeSession(current);
    if (_disposed || revision != _revision) return;
    if (!_canNavigate) {
      if (current == null) _pendingPayload = null;
      return;
    }
    if (_transportReady) unawaited(_protect(_facade.synchronizeDevice));
    final payload = _pendingPayload;
    _pendingPayload = null;
    if (payload != null) await _open(payload);
  }

  Future<void> _open(String payload) async {
    if (_disposed || OmissionPushPayload.decode(payload) == null) return;
    await _sessions.initialize();
    if (_disposed) return;
    if (!_canNavigate) {
      if (_sessions.current != null) _pendingPayload = payload;
      return;
    }
    final revision = _revision;
    final generation = _sessions.generation;
    final destination = await _facade.destination(payload);
    if (!_disposed &&
        _canNavigate &&
        revision == _revision &&
        generation == _sessions.generation &&
        destination != null) {
      _destinations.add(destination);
    }
  }

  /// Stops queued navigation before bounded authenticated device removal.
  Future<void> beforeSignOut() async {
    _revision++;
    _canNavigate = false;
    _pendingPayload = null;
    await _facade.beforeSignOut();
  }

  static void _ignoreTransportError(Object _, StackTrace _) {
    // Provider diagnostics never become clinical state or user-visible messages.
  }

  Future<void> _protect(Future<void> Function() operation) async {
    if (_disposed) return;
    try {
      await operation();
    } on Exception {
      // A failed SDK event must not interrupt session cleanup or later events.
    }
  }

  Future<void> dispose() async {
    _disposed = true;
    _revision++;
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    _facade.dispose();
    await _destinations.close();
  }
}
