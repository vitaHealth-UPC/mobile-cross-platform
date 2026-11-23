/// Screen a tapped omission notification opens.
sealed class PushDestination {
  const PushDestination();
}

/// Alerts of the older adult. The app resolves the exact intake when supplied and keeps
/// medication matching for legacy messages without that reference.
final class CaregiverAlertsDestination extends PushDestination {
  const CaregiverAlertsDestination({
    required this.caregiverId,
    required this.olderAdultId,
    this.medicationName,
    this.intakeId,
  });
  final String caregiverId;
  final String olderAdultId;
  final String? medicationName;
  final String? intakeId;
}

/// Home of the older adult, where the pending intake can be confirmed.
final class OlderAdultHomeDestination extends PushDestination {
  const OlderAdultHomeDestination({
    required this.olderAdultId,
    required this.olderAdultName,
  });
  final String olderAdultId;
  final String olderAdultName;
}

/// Exact intake carried by a versioned reminder, independent of the next-dose selection.
final class OlderAdultDoseDestination extends PushDestination {
  const OlderAdultDoseDestination({
    required this.olderAdultId,
    required this.intakeId,
  });
  final String olderAdultId;
  final String intakeId;
}
