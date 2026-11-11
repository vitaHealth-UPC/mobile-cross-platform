import '../../../../shared/application/session/session_owner.dart';
import '../../../../shared/common/result/app_result.dart';
import '../ports/intake_confirmation.dart';
import '../ports/intake_local_store.dart';

enum ReplayOutcome {
  /// Every queued confirmation received a definitive server answer.
  complete,

  /// A transient failure ended the pass; the queue is intact from that entry.
  retry,

  /// The session changed or lost access; nothing more may be sent with it.
  stopped,
}

final class ReplayResult {
  const ReplayResult(this.outcome, this.resolved);
  final ReplayOutcome outcome;

  /// Entries the server answered during this pass.
  final int resolved;
}

/// Sends one adult's queue oldest first. Repeating a delivery is safe because
/// the server replays an existing confirmation without duplicating it.
final class ReplayPendingConfirmations {
  const ReplayPendingConfirmations(this._remote, this._local, this._isCurrent);

  final IntakeConfirmationReplay _remote;
  final IntakeLocalStore _local;
  final bool Function(SessionOwner owner) _isCurrent;

  Future<ReplayResult> call(SessionOwner owner) async {
    var resolved = 0;
    for (final item in await _local.pendingConfirmations(owner)) {
      if (!_isCurrent(owner)) {
        return ReplayResult(ReplayOutcome.stopped, resolved);
      }
      var result = await _remote.replay(item.intakeId, item.queuedAt);
      if (!_isCurrent(owner)) {
        return ReplayResult(ReplayOutcome.stopped, resolved);
      }
      // A wrong device clock must not strand the dose: arrival time is true.
      if (result case AppFailure(code: 'INVALID_CONFIRMATION_TIME')) {
        result = await _remote.confirm(item.intakeId);
        if (!_isCurrent(owner)) {
          return ReplayResult(ReplayOutcome.stopped, resolved);
        }
      }
      switch (result) {
        case AppSuccess(:final value):
          await _local.acknowledgeConfirmation(owner, value.intake);
          resolved++;
        case AppFailure(
          code: final code && ('INTAKE_NOT_FOUND' || 'INTAKE_NOT_CONFIRMABLE'),
        ):
          await _local.rejectConfirmation(owner, item.intakeId, code);
          resolved++;
        case AppFailure(
          code: 'AUTHENTICATION_REQUIRED' ||
              'ACCESS_DENIED' ||
              'SESSION_CHANGED',
        ):
          return ReplayResult(ReplayOutcome.stopped, resolved);
        case AppFailure():
          return ReplayResult(ReplayOutcome.retry, resolved);
      }
    }
    return ReplayResult(ReplayOutcome.complete, resolved);
  }
}
