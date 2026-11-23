import '../../../../shared/common/result/app_result.dart';
import '../../domain/value_objects/omission_push.dart';
import '../policies/omission_push_access_policy.dart';
import '../ports/omission_ports.dart';
import '../readmodels/push_destination.dart';

/// Stable validation code of the follow-up commands.
const invalidFollowUpReference = 'INVALID_FOLLOW_UP_REFERENCE';

/// The caregiver opened the follow-up of an older adult and wants its missed-dose alerts.
/// Remembers a navigation target; clinical delivery uses authenticated device registration.
final class FollowCaregiverAlerts {
  const FollowCaregiverAlerts(this._store);
  final PushTargetStore _store;

  Future<AppResult<void>> call({
    required String caregiverId,
    required String olderAdultId,
  }) async {
    final caregiver = caregiverId.trim();
    final adult = olderAdultId.trim();
    if (caregiver.isEmpty || adult.isEmpty) {
      return const AppFailure(invalidFollowUpReference);
    }
    await _store.rememberCaregiver(adult, caregiver);
    return const AppSuccess(null);
  }
}

/// The older adult signed in on this device and wants the reinforced reminders of their
/// intakes. Remembers the display target without subscribing to public clinical topics.
final class FollowDoseReminders {
  const FollowDoseReminders(this._store);
  final PushTargetStore _store;

  Future<AppResult<void>> call({
    required String olderAdultId,
    required String olderAdultName,
  }) async {
    final adult = olderAdultId.trim();
    if (adult.isEmpty) return const AppFailure(invalidFollowUpReference);
    await _store.rememberOlderAdult(adult, olderAdultName.trim());
    return const AppSuccess(null);
  }
}

/// References supplied by a notification tap before recipient authorization and route
/// resolution.
final class ResolvePushDestinationQuery {
  const ResolvePushDestinationQuery({
    required this.kind,
    required this.olderAdultId,
    this.medicationName,
    this.intakeId,
  });
  final OmissionPushKind kind;
  final String olderAdultId;
  final String? medicationName;
  final String? intakeId;
}

/// Resolves exact intake references and legacy targets before separate session
/// authorization.
final class ResolvePushDestination {
  const ResolvePushDestination(this._store);
  final PushTargetStore _store;

  Future<PushDestination?> call(ResolvePushDestinationQuery query) async {
    final adult = query.olderAdultId.trim();
    if (adult.isEmpty) return null;
    final intakeId = query.intakeId?.trim();
    if (intakeId != null && intakeId.isEmpty) return null;
    switch (query.kind) {
      case OmissionPushKind.caregiverAlert:
        final caregiver = await _store.caregiverFor(adult);
        if (caregiver == null) return null;
        final medication = query.medicationName;
        return CaregiverAlertsDestination(
          caregiverId: caregiver,
          olderAdultId: adult,
          medicationName: medication == null || medication.trim().isEmpty
              ? null
              : medication,
          intakeId: intakeId,
        );
      case OmissionPushKind.reinforcedReminder:
        if (intakeId != null) {
          return OlderAdultDoseDestination(
            olderAdultId: adult,
            intakeId: intakeId,
          );
        }
        final name = await _store.olderAdultName(adult);
        return name == null
            ? null
            : OlderAdultHomeDestination(
                olderAdultId: adult,
                olderAdultName: name,
              );
    }
  }
}

/// Shows a received push only while the signed-in owner is its recipient.
/// Returns whether the notice was shown.
final class HandleIncomingOmissionPush {
  const HandleIncomingOmissionPush(this._policy, this._notifier);
  final OmissionPushAccessPolicy _policy;
  final OmissionNotifier _notifier;

  Future<bool> call(OmissionPush push) async {
    if (!await _policy.allows(push)) return false;
    await _notifier.show(push);
    return true;
  }
}
