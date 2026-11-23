import '../../domain/value_objects/omission_push.dart';
import '../ports/push_target_store.dart';
import '../readmodels/push_destination.dart';

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
