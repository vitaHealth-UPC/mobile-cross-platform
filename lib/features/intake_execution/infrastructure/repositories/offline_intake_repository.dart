import 'dart:async';

import '../../../../shared/application/session/session_owner.dart';
import '../../../../shared/application/session/session_store.dart';
import '../../../../shared/application/time/clock.dart';
import '../../../../shared/common/result/app_result.dart';
import '../../application/ports/intake_confirmation.dart';
import '../../application/ports/intake_local_store.dart';
import '../../application/ports/intake_reader.dart';
import '../../application/readmodels/confirmation_receipt.dart';
import '../../application/readmodels/intake_sync_status.dart';
import '../../domain/entities/intake.dart';

/// Answers from the server and falls back to the device only when the network
/// fails. A queued confirmation is reported as `PENDING_SYNC`, never as a
/// server receipt, and stored data is partitioned by the captured adult.
final class OfflineIntakeRepository
    implements IntakeReader, IntakeConfirmation {
  OfflineIntakeRepository({
    required this._remoteReader,
    required this._remoteConfirmation,
    required this._local,
    required this._store,
    required this._clock,
  });

  final IntakeReader _remoteReader;
  final IntakeConfirmation _remoteConfirmation;
  final IntakeLocalStore _local;
  final SessionStore _store;
  final Clock _clock;
  final _changes = StreamController<IntakeSyncStatus>.broadcast();
  IntakeSyncStatus _status = const IntakeSyncStatus();

  IntakeSyncStatus get status => _status;
  Stream<IntakeSyncStatus> get changes => _changes.stream;

  @override
  Future<AppResult<Intake?>> next() => _read(
    remote: _remoteReader.next,
    fresh: (owner, value) async {
      final now = _clock().toUtc();
      if (value == null) {
        await _local.clearUpcoming(owner, now);
        return null;
      }
      await _local.cacheIntake(owner, value);
      final marks = await _local.localConfirmations(owner);
      // The server cannot know yet that this dose was already confirmed here.
      return marks[value.id] == LocalConfirmation.queued
          ? _local.findNext(owner, now, excluding: _queued(marks))
          : value;
    },
    stored: (owner) async {
      final queued = _queued(await _local.localConfirmations(owner));
      final next = await _local.findNext(
        owner,
        _clock().toUtc(),
        excluding: queued,
      );
      // With nothing stored the schedule is unknown, not empty.
      return next != null || queued.isNotEmpty ? AppSuccess(next) : null;
    },
  );

  @override
  Future<AppResult<List<Intake>>> agenda(DateTime from, DateTime to) => _read(
    remote: () => _remoteReader.agenda(from, to),
    fresh: (owner, value) async {
      await _local.replaceAgenda(owner, from, to, value);
      return _marked(owner, value);
    },
    stored: (owner) async {
      final stored = await _local.findAgenda(owner, from, to);
      return stored.isEmpty ? null : AppSuccess(await _marked(owner, stored));
    },
  );

  @override
  Future<AppResult<Intake>> detail(String intakeId) => _read(
    remote: () => _remoteReader.detail(intakeId),
    fresh: (owner, value) async {
      await _local.cacheIntake(owner, value);
      return (await _marked(owner, [value])).single;
    },
    stored: (owner) async {
      final stored = await _local.findIntake(owner, intakeId);
      return stored == null
          ? null
          : AppSuccess((await _marked(owner, [stored])).single);
    },
  );

  @override
  Future<AppResult<ConfirmationReceipt>> confirm(String intakeId) async {
    final owner = await _captureAdult();
    // Taken before the request, which can take seconds to time out.
    final confirmedAt = _clock().toUtc();
    final result = await _remoteConfirmation.confirm(intakeId);
    if (owner == null || !_isCurrent(owner)) return result;
    try {
      switch (result) {
        case AppSuccess(:final value):
          _setOffline(false);
          await _local.acknowledgeConfirmation(owner, value.intake);
          await refreshStatus();
        case AppFailure(code: 'NETWORK_UNAVAILABLE'):
          _setOffline(true);
          // Only a dose this adult has already seen can be confirmed offline.
          if (await _local.findIntake(owner, intakeId) != null &&
              _isCurrent(owner)) {
            await _local.enqueueConfirmation(owner, intakeId, confirmedAt);
            await refreshStatus();
            return const AppFailure('PENDING_SYNC');
          }
        case AppFailure():
          break;
      }
    } on Exception {
      // Without storage the original server answer is the only truthful one.
    }
    return result;
  }

  /// Recounts the current adult's queue after it changed.
  Future<void> refreshStatus({int resolved = 0}) async {
    final owner = _store.current?.owner;
    final queued = owner?.role == SessionRole.olderAdult
        ? (await _local.pendingConfirmations(owner!)).length
        : 0;
    _publish(
      IntakeSyncStatus(
        queued: queued,
        offline: _status.offline,
        resolved: _status.resolved + resolved,
      ),
    );
  }

  Future<void> dispose() => _changes.close();

  Future<AppResult<T>> _read<T>({
    required Future<AppResult<T>> Function() remote,
    required Future<T> Function(SessionOwner owner, T value) fresh,
    required Future<AppResult<T>?> Function(SessionOwner owner) stored,
  }) async {
    final owner = await _captureAdult();
    final result = await remote();
    if (owner == null || !_isCurrent(owner)) return result;
    try {
      final AppResult<T>? answer;
      switch (result) {
        case AppSuccess(:final value):
          _setOffline(false);
          answer = AppSuccess(await fresh(owner, value));
        case AppFailure(code: 'NETWORK_UNAVAILABLE'):
          _setOffline(true);
          answer = await stored(owner);
        case AppFailure():
          answer = null;
      }
      if (!_isCurrent(owner)) return const AppFailure('SESSION_CHANGED');
      return answer ?? result;
    } on Exception {
      return result;
    }
  }

  Future<SessionOwner?> _captureAdult() async {
    try {
      await _store.initialize();
    } on Exception {
      return null;
    }
    final owner = _store.current?.owner;
    return owner?.role == SessionRole.olderAdult ? owner : null;
  }

  bool _isCurrent(SessionOwner owner) => _store.current?.owner == owner;

  Future<List<Intake>> _marked(SessionOwner owner, List<Intake> intakes) async {
    final marks = await _local.localConfirmations(owner);
    return [
      for (final intake in intakes)
        switch (marks[intake.id]) {
          // Once the server has its own answer, a queued mark no longer applies.
          LocalConfirmation.queued when intake.confirmable =>
            intake.withLocalConfirmation(LocalConfirmation.queued),
          LocalConfirmation.rejected => intake.withLocalConfirmation(
            LocalConfirmation.rejected,
          ),
          _ => intake,
        },
    ];
  }

  Set<String> _queued(Map<String, LocalConfirmation> marks) => {
    for (final MapEntry(:key, :value) in marks.entries)
      if (value == LocalConfirmation.queued) key,
  };

  void _setOffline(bool offline) => _publish(
    IntakeSyncStatus(
      queued: _status.queued,
      offline: offline,
      resolved: _status.resolved,
    ),
  );

  void _publish(IntakeSyncStatus status) {
    if (status == _status) return;
    _status = status;
    if (!_changes.isClosed) _changes.add(status);
  }
}
