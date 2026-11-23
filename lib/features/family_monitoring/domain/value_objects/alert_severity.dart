/// Operational follow-up priority classified by the server from recorded escalation.
/// [unknown] also represents an older server response without classification.
enum AlertSeverity {
  unknown('UNKNOWN'),
  standard('STANDARD'),
  high('HIGH'),
  critical('CRITICAL');

  const AlertSeverity(this.wireName);
  final String wireName;

  static AlertSeverity? fromWire(Object? value) {
    if (value == null) return unknown;
    for (final severity in values) {
      if (severity.wireName == value) return severity;
    }
    return null;
  }
}
