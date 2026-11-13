import '../value_objects/alert_status.dart';

/// Alert raised by an intake that was not confirmed in time, seen from the caregiver side.
final class CaregiverAlert {
  CaregiverAlert({
    required this.id,
    required this.intakeId,
    required this.medicationName,
    required this.scheduledAt,
    required this.reason,
    required this.status,
    required this.openedAt,
    required this.closedAt,
  }) {
    if (id <= 0) throw ArgumentError('Alert id must be positive');
    if (intakeId.trim().isEmpty) {
      throw ArgumentError('Alert intake is required');
    }
    if (medicationName.trim().isEmpty) {
      throw ArgumentError('Alert medication is required');
    }
    if ((status == AlertStatus.closed) != (closedAt != null)) {
      throw ArgumentError('Closed alerts must carry their closing instant');
    }
    if (closedAt != null && closedAt!.isBefore(openedAt)) {
      throw ArgumentError('An alert cannot close before it opens');
    }
  }

  final int id;
  final String intakeId;
  final String medicationName;
  final DateTime scheduledAt;
  final String reason;
  final AlertStatus status;
  final DateTime openedAt;
  final DateTime? closedAt;
}
