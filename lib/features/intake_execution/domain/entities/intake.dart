/// Server-owned intake outcome; the client never decides a final status.
enum IntakeStatus { pending, confirmed, late, omitted }

/// Device-only state of a confirmation without a server receipt.
enum LocalConfirmation {
  none,

  /// Saved on the device and waiting for connection.
  queued,

  /// The server refused it when it finally arrived.
  rejected,
}

/// One scheduled dose of a treatment with its current evidence.
final class Intake {
  const Intake({
    required this.id,
    required this.olderAdultId,
    required this.medicationName,
    required this.dose,
    required this.scheduledAt,
    required this.status,
    this.medicationId,
    this.treatmentId,
    this.instructions,
    this.confirmedAt,
    this.localConfirmation = LocalConfirmation.none,
  });

  final String id;

  /// Source references supplied by remote evidence; older local snapshots may lack them.
  final String? medicationId;
  final String? treatmentId;
  final String olderAdultId;
  final String medicationName;
  final String dose;
  final String? instructions;

  /// UTC instant; presentation converts it to the device time zone.
  final DateTime scheduledAt;
  final IntakeStatus status;

  /// UTC instant of the recorded confirmation; null unless confirmed or late.
  final DateTime? confirmedAt;
  final LocalConfirmation localConfirmation;

  /// Confirmed on time or late both count as taken; omitted does not.
  bool get taken =>
      status == IntakeStatus.confirmed || status == IntakeStatus.late;

  /// True while this device holds an unsent confirmation of the dose.
  bool get queued => localConfirmation == LocalConfirmation.queued;

  /// Only pending evidence accepts a confirmation; the server still decides.
  /// A queued dose is not offered again, so it cannot be taken twice by mistake.
  bool get confirmable => status == IntakeStatus.pending && !queued;

  Intake withLocalConfirmation(LocalConfirmation value) => Intake(
    id: id,
    medicationId: medicationId,
    treatmentId: treatmentId,
    olderAdultId: olderAdultId,
    medicationName: medicationName,
    dose: dose,
    instructions: instructions,
    scheduledAt: scheduledAt,
    status: status,
    confirmedAt: confirmedAt,
    localConfirmation: value,
  );

  @override
  String toString() => 'Intake[status=$status, clinicalData=REDACTED]';
}
