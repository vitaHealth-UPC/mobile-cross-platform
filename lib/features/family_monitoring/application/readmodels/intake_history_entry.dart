/// Recorded outcomes supported by the family intake history.
enum IntakeHistoryOutcome { confirmed, late, omitted }

/// A historical intake without display formatting or a device-specific time zone.
final class IntakeHistoryEntry {
  const IntakeHistoryEntry({
    required this.medicationName,
    required this.scheduledAt,
    required this.outcome,
  });
  final String medicationName;
  final DateTime scheduledAt;
  final IntakeHistoryOutcome outcome;
}
