/// The two notifications the backend Omission & Escalation context sends (TS-05 / TS-06).
enum OmissionPushKind {
  /// Reinforced reminder to the older adult while the intake is still pending (US-22).
  reinforcedReminder('REINFORCED_REMINDER'),

  /// Alert to the caregivers once the intake is registered as omitted.
  caregiverAlert('CAREGIVER_ALERT');

  const OmissionPushKind(this.wireName);

  /// Name used by the backend data messages and by notification payloads.
  final String wireName;

  /// Null for any value that is not one of the two known kinds.
  static OmissionPushKind? fromWire(String? value) {
    for (final kind in values) {
      if (kind.wireName == value) return kind;
    }
    return null;
  }
}

/// Notification evidence shared by versioned data messages and legacy topic delivery.
final class OmissionPush {
  OmissionPush({
    required this.kind,
    required this.olderAdultId,
    this.medicationName,
    this.deliveryId,
    this.intakeId,
    this.scheduledAt,
  }) {
    if (olderAdultId.trim().isEmpty) {
      throw ArgumentError('A push must identify the affected older adult');
    }
    if (deliveryId != null && deliveryId!.trim().isEmpty) {
      throw ArgumentError('Delivery ID cannot be blank when present');
    }
    if (intakeId != null && intakeId!.trim().isEmpty) {
      throw ArgumentError('Intake ID cannot be blank when present');
    }
  }

  final OmissionPushKind kind;
  final String olderAdultId;
  final String? medicationName;
  final String? deliveryId;
  final String? intakeId;
  final DateTime? scheduledAt;
}
