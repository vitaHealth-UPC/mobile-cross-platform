/// Follow-up status of an alert, as the backend Alerts resource defines it.
/// The declaration order is the display order: pending first, then attended and closed.
enum AlertStatus {
  open('OPEN'),
  attended('ATTENDED'),
  closed('CLOSED');

  const AlertStatus(this.wireName);

  /// Name used by the backend resource.
  final String wireName;

  /// Rejects unknown lifecycle states rather than inferring an open alert.
  static AlertStatus? fromWire(Object? value) {
    for (final status in values) {
      if (status.wireName == value) return status;
    }
    return null;
  }

  /// Follow-up moves a caregiver can request: attend an open alert, or close an open or
  /// attended one. The backend keeps the final word and answers 409 when it already moved.
  bool canMoveTo(AlertStatus target) => switch (this) {
    AlertStatus.open =>
      target == AlertStatus.attended || target == AlertStatus.closed,
    AlertStatus.attended => target == AlertStatus.closed,
    AlertStatus.closed => false,
  };
}
