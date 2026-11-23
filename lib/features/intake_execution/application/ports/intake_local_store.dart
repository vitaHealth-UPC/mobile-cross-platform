import '../../../../shared/application/session/session_owner.dart';
import '../../domain/entities/intake.dart';
import '../readmodels/pending_confirmation.dart';

/// Device storage of server intakes and unsent confirmations, one partition
/// per adult and care link, so another account can never read or send them.
abstract interface class IntakeLocalStore {
  /// Saves the last validated server representation of one intake.
  Future<void> cacheIntake(SessionOwner owner, Intake intake);

  /// Replaces the half-open UTC interval [from, to) with the server's answer.
  Future<void> replaceAgenda(
    SessionOwner owner,
    DateTime from,
    DateTime to,
    List<Intake> intakes,
  );

  /// Removes stored pending intakes after the server reported none upcoming.
  Future<void> clearUpcoming(SessionOwner owner, DateTime from);

  Future<Intake?> findIntake(SessionOwner owner, String intakeId);

  /// Earliest stored pending intake at or after [from], skipping [excluding].
  Future<Intake?> findNext(
    SessionOwner owner,
    DateTime from, {
    Set<String> excluding = const {},
  });

  /// Stored intakes of the half-open UTC interval [from, to), by schedule.
  Future<List<Intake>> findAgenda(
    SessionOwner owner,
    DateTime from,
    DateTime to,
  );

  /// Keeps the first intent when the same intake is queued again.
  Future<void> enqueueConfirmation(
    SessionOwner owner,
    String intakeId,
    DateTime queuedAt,
  );

  /// Confirmations still to be sent, oldest first.
  Future<List<PendingConfirmation>> pendingConfirmations(SessionOwner owner);

  /// Device-only state of each intake that has an entry in the queue.
  Future<Map<String, LocalConfirmation>> localConfirmations(SessionOwner owner);

  /// Stores the server receipt and clears its queue entry in one transaction.
  Future<void> acknowledgeConfirmation(SessionOwner owner, Intake intake);

  /// Keeps a definitive rejection so the adult can learn it was not recorded.
  Future<void> rejectConfirmation(
    SessionOwner owner,
    String intakeId,
    String code,
  );

  /// Deletes everything stored for an adult, for example after consent withdrawal.
  Future<void> clearAdult(String olderAdultId);
}
