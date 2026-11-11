import 'dart:async';

import '../../../../shared/application/session/session_owner.dart';
import '../../../../shared/application/session/session_store.dart';
import '../../../../shared/application/time/clock.dart';
import '../../application/ports/intake_sync.dart';
import '../../application/readmodels/intake_sync_status.dart';
import '../../application/usecases/replay_pending_confirmations.dart';
import '../repositories/offline_intake_repository.dart';

/// Runs delivery one pass at a time for the adult in session, retries while
/// the app is open, and then stores the coming week for offline use.
final class IntakeSyncCoordinator implements IntakeSync {
  IntakeSyncCoordinator({
    required this._store,
    required this._repository,
    required this._replay,
    required this._clock,
    this.retryDelay = const Duration(seconds: 30),
  }) {
    _subscription = _repository.changes.listen((status) {
      if (status.queued > 0 && _active == null) _scheduleRetry();
    });
  }

  /// Agenda queries accept at most eight days.
  static const _prefetchWindow = Duration(days: 7);

  final SessionStore _store;
  final OfflineIntakeRepository _repository;
  final ReplayPendingConfirmations _replay;
  final Clock _clock;
  final Duration retryDelay;
  late final StreamSubscription<IntakeSyncStatus> _subscription;
  Future<void>? _active;
  Timer? _timer;
  var _runAgain = false;
  var _suspended = false;
  var _lastOutcome = ReplayOutcome.complete;

  @override
  IntakeSyncStatus get status => _repository.status;

  @override
  Stream<IntakeSyncStatus> get changes => _repository.changes;

  @override
  Future<void> request() {
    _suspended = false;
    _cancelRetry();
    final active = _active;
    if (active != null) {
      _runAgain = true;
      return active;
    }
    return _active = _run().whenComplete(() {
      _active = null;
      if (status.queued > 0 && _lastOutcome != ReplayOutcome.stopped) {
        _scheduleRetry();
      }
    });
  }

  @override
  void suspend() {
    _suspended = true;
    _cancelRetry();
  }

  Future<void> dispose() async {
    suspend();
    await _subscription.cancel();
    await _active;
  }

  Future<void> _run() async {
    do {
      _runAgain = false;
      await _pass();
    } while (_runAgain);
  }

  Future<void> _pass() async {
    try {
      await _store.initialize();
      final owner = _store.current?.owner;
      if (owner?.role != SessionRole.olderAdult) {
        _lastOutcome = ReplayOutcome.stopped;
        await _repository.refreshStatus();
        return;
      }
      final result = await _replay(owner!);
      _lastOutcome = result.outcome;
      await _repository.refreshStatus(resolved: result.resolved);
      if (result.outcome == ReplayOutcome.complete) {
        final now = _clock().toUtc();
        await _repository.agenda(now, now.add(_prefetchWindow));
      }
    } on Exception {
      _lastOutcome = ReplayOutcome.retry;
    }
  }

  void _scheduleRetry() {
    if (_suspended || _timer != null) return;
    _timer = Timer(retryDelay, () {
      _timer = null;
      unawaited(request());
    });
  }

  void _cancelRetry() {
    _timer?.cancel();
    _timer = null;
  }
}
