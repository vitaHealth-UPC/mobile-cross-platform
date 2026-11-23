enum RecordedAlertEventType {
  intakeScheduled('INTAKE_SCHEDULED'),
  reinforcedReminderSent('REINFORCED_REMINDER_SENT'),
  alertGenerated('ALERT_GENERATED'),
  alertClosed('ALERT_CLOSED');

  const RecordedAlertEventType(this.wireName);
  final String wireName;

  static RecordedAlertEventType? fromWire(Object? value) {
    for (final type in values) {
      if (type.wireName == value) return type;
    }
    return null;
  }
}

/// One step the backend recorded for an alert.
final class RecordedAlertEvent {
  const RecordedAlertEvent({required this.type, required this.occurredAt});
  final RecordedAlertEventType type;
  final DateTime occurredAt;
}
