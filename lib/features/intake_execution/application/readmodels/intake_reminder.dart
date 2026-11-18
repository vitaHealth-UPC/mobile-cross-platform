/// Which reminder of a dose: at its time (US-05) or still pending later (US-22).
enum ReminderKind { due, reinforced }

/// One device reminder for a pending dose. Instants are UTC.
final class IntakeReminder {
  const IntakeReminder({
    required this.intakeId,
    required this.kind,
    required this.at,
    required this.medicationName,
    required this.dose,
  });

  final String intakeId;
  final ReminderKind kind;
  final DateTime at;
  final String medicationName;
  final String dose;

  /// Stable per dose and kind, so rescheduling replaces instead of duplicating.
  int get notificationId {
    var hash = 0x811C9DC5;
    for (final unit in intakeId.codeUnits) {
      hash = ((hash ^ unit) * 0x01000193) & 0x3FFFFFFF;
    }
    return hash * 2 + kind.index;
  }

  @override
  bool operator ==(Object other) =>
      other is IntakeReminder &&
      other.intakeId == intakeId &&
      other.kind == kind &&
      other.at == at &&
      other.medicationName == medicationName &&
      other.dose == dose;

  @override
  int get hashCode => Object.hash(intakeId, kind, at, medicationName, dose);

  @override
  String toString() => 'IntakeReminder[$kind, clinicalData=REDACTED]';
}
