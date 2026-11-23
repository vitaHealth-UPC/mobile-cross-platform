/// Scheduled medication dose exposed to the family monitoring view.
final class MonitoredDose {
  const MonitoredDose({
    required this.id,
    required this.medicationId,
    required this.medicationName,
    required this.dose,
    required this.scheduledAt,
    required this.status,
    this.confirmedAt,
  });

  /// `PENDING`, `CONFIRMED`, `LATE` or `OMITTED`, as the intake resource states it.
  static const statuses = {'PENDING', 'CONFIRMED', 'LATE', 'OMITTED'};

  final String id;
  final String medicationId;
  final String medicationName;
  final String dose;
  final DateTime scheduledAt;
  final String status;

  /// Server-recorded confirmation instant; absence never implies the scheduled time.
  final DateTime? confirmedAt;

  bool get isDone => status == 'CONFIRMED' || status == 'LATE';
}
