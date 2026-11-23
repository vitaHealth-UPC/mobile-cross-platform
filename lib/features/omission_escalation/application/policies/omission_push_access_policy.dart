import '../../../../shared/application/session/session_owner.dart';
import '../../../../shared/application/session/session_store.dart';
import '../../../../shared/application/session/stored_session.dart';
import '../../../../shared/application/time/clock.dart';
import '../../domain/value_objects/omission_push.dart';
import '../ports/omission_ports.dart';
import '../readmodels/push_destination.dart';

/// Prevents delayed messages from displaying after logout or under a different recipient
/// account, and revalidates a stored notification tap instead of trusting its earlier decision.
final class OmissionPushAccessPolicy {
  OmissionPushAccessPolicy({
    required this._sessions,
    required this._targets,
    Clock? now,
  }) : _now = now ?? DateTime.now;

  final SessionStore _sessions;
  final PushTargetStore _targets;
  final Clock _now;

  Future<bool> allowsDestination(PushDestination destination) async {
    final session = await _session();
    if (session == null) return false;
    return switch (destination) {
      CaregiverAlertsDestination() =>
        session.owner.id == destination.caregiverId &&
            await _allows(
              OmissionPush(
                kind: OmissionPushKind.caregiverAlert,
                olderAdultId: destination.olderAdultId,
              ),
              session,
            ),
      OlderAdultHomeDestination() => await _allows(
        OmissionPush(
          kind: OmissionPushKind.reinforcedReminder,
          olderAdultId: destination.olderAdultId,
        ),
        session,
      ),
      OlderAdultDoseDestination() => await _allows(
        OmissionPush(
          kind: OmissionPushKind.reinforcedReminder,
          olderAdultId: destination.olderAdultId,
        ),
        session,
      ),
    };
  }

  /// Whether the signed-in owner is the recipient of [push].
  Future<bool> allows(OmissionPush push) async {
    final session = await _session();
    return session != null && await _allows(push, session);
  }

  Future<StoredSession?> _session() async {
    await _sessions.initialize();
    return _sessions.current;
  }

  Future<bool> _allows(OmissionPush push, StoredSession session) async {
    if (!session.isValidAt(_now())) return false;
    final owner = session.owner;
    return switch (push.kind) {
      OmissionPushKind.reinforcedReminder =>
        owner.role == SessionRole.olderAdult && owner.id == push.olderAdultId,
      OmissionPushKind.caregiverAlert =>
        owner.role == SessionRole.caregiver &&
            await _targets.caregiverFor(push.olderAdultId) == owner.id,
    };
  }
}
