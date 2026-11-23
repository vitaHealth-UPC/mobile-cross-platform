/// Server-owned intake outcome; the client never decides a final status.
enum IntakeStatus { pending, confirmed, late, omitted }

/// One scheduled dose of a treatment with its current evidence.
final class Intake {
  const Intake({
    required this.id,
    required this.olderAdultId,
    required this.medicationName,
    required this.dose,
    required this.scheduledAt,
    required this.status,
    this.instructions,
  });

  final String id;
  final String olderAdultId;
  final String medicationName;
  final String dose;
  final String? instructions;

  /// UTC instant; presentation converts it to the device time zone.
  final DateTime scheduledAt;
  final IntakeStatus status;

  /// Confirmed on time or late both count as taken; omitted does not.
  bool get taken =>
      status == IntakeStatus.confirmed || status == IntakeStatus.late;

  @override
  String toString() => 'Intake[status=$status, clinicalData=REDACTED]';
}
