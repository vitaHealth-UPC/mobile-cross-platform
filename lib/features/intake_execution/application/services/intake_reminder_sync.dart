import 'dart:async';

import '../../../../shared/application/session/session_owner.dart';
import '../../../../shared/application/session/session_store.dart';
import '../../../../shared/application/time/clock.dart';
import '../../domain/entities/intake.dart';
import '../policies/intake_reminder_policy.dart';
import '../ports/intake_local_store.dart';
import '../ports/reminder_scheduler.dart';
import '../readmodels/intake_reminder.dart';

/// Keeps device reminders equal to the adult's stored agenda. Any change of
/// the local store (a refresh, a confirmation queued or acknowledged, consent
/// data removed) reschedules them, also without connection.
final class IntakeReminderSync {
  IntakeReminderSync({
    required this._local,
    required this._sessions,
    required this._scheduler,
    this._clock = DateTime.now,
  });

  final IntakeLocalStore _local;
  final SessionStore _sessions;
  final ReminderScheduler _scheduler;
  final Clock _clock;

  StreamSubscription<void>? _changes;
  SessionOwner? _owner;
  List<IntakeReminder>? _scheduled;
  Future<void> _queue = Future.value();

  Stream<String> get opened => _scheduler.opened;

  Future<String?> takeLaunchDose() => _scheduler.takeLaunchDose();

  /// Starts following [olderAdultId] when it is the adult of the session.
  Future<void> start(String olderAdultId) async {
    await _sessions.initialize();
    final owner = _sessions.current?.owner;
    if (owner == null ||
        owner.role != SessionRole.olderAdult ||
        owner.id != olderAdultId) {
      return;
    }
    if (_owner == owner && _changes != null) return refresh();
    await _changes?.cancel();
    _owner = owner;
    _scheduled = null;
    await _scheduler.prepare();
    _changes = _local.changes().listen((_) => unawaited(refresh()));
    await refresh();
  }

  /// Recomputes reminders now; calls are serialized.
  Future<void> refresh() => _queue = _queue.then((_) => _sync());

  /// Session ended, changed or lost consent: nothing clinical stays scheduled.
  Future<void> stop() async {
    await _changes?.cancel();
    _changes = null;
    _owner = null;
    _scheduled = null;
    _queue = _queue.then((_) => _scheduler.cancelAll());
    await _queue;
  }

  Future<void> _sync() async {
    final owner = _owner;
    if (owner == null) return;
    try {
      final now = _clock().toUtc();
      final stored = await _local.findAgenda(
        owner,
        now.subtract(IntakeReminderPolicy.reinforceAfter),
        now.add(IntakeReminderPolicy.horizon),
      );
      final marks = await _local.localConfirmations(owner);
      final intakes = [
        for (final intake in stored)
          intake.withLocalConfirmation(
            marks[intake.id] ?? LocalConfirmation.none,
          ),
      ];
      final plan = IntakeReminderPolicy.plan(intakes, now);
      if (_owner != owner || _same(plan, _scheduled)) return;
      await _scheduler.replaceAll(plan);
      _scheduled = plan;
    } on Object {
      // A storage or platform failure keeps the previous reminders; the next
      // change of the store tries again.
    }
  }

  static bool _same(List<IntakeReminder> a, List<IntakeReminder>? b) {
    if (b == null || a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
