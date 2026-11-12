import '../../domain/value_objects/treatment_status.dart';

/// Treatment identity, lifecycle state and optional regimen details for read-only views.
/// A draft carries no regimen; the client never invents one.
final class TreatmentDetail {
  const TreatmentDetail({
    required this.id,
    required this.olderAdultId,
    required this.name,
    required this.status,
    this.medicationId,
    this.dose,
    this.frequency,
    this.scheduledTimes = const [],
    this.instructions = '',
    this.reminderLeadMinutes,
    this.followUpDelayMinutes,
  });

  final String id;
  final String olderAdultId;
  final String name;
  final TreatmentStatus status;
  final String? medicationId;
  final String? dose;
  final String? frequency;

  /// Local times as `HH:mm`, in ascending order.
  final List<String> scheduledTimes;
  final String instructions;
  final int? reminderLeadMinutes;

  /// Null when the system default follow-up applies.
  final int? followUpDelayMinutes;

  bool get isDraft => status == TreatmentStatus.draft;

  /// True when a regimen was configured for this treatment.
  bool get configured =>
      dose != null && frequency != null && scheduledTimes.isNotEmpty;

  @override
  String toString() => 'TreatmentDetail[status=$status, clinicalData=REDACTED]';
}

/// Medication of the signed-in adult with the regimen that applies to it.
final class MyMedication {
  const MyMedication({
    required this.id,
    required this.name,
    required this.presentation,
    required this.active,
    required this.dose,
    required this.instructions,
    required this.scheduledTimes,
  });

  final String id;
  final String name;
  final String presentation;

  /// True only when the medication is available and one of its treatments is active.
  final bool active;
  final String dose;
  final String instructions;
  final List<String> scheduledTimes;

  /// Instructions when present, otherwise the scheduled times.
  String get scheduleLabel => instructions.trim().isNotEmpty
      ? instructions
      : scheduledTimes.join(' · ');

  @override
  String toString() => 'MyMedication[clinicalData=REDACTED]';
}

/// Next scheduled intake, identified by the medication it belongs to.
final class MedicationNextDose {
  const MedicationNextDose({
    required this.intakeId,
    required this.medicationName,
    required this.scheduledAt,
  });

  final String intakeId;
  final String medicationName;

  /// UTC instant; presentation converts it to the device time zone.
  final DateTime scheduledAt;
}

/// Medication catalog paired with the next intake available for the same adult.
final class MyMedicationsOverview {
  const MyMedicationsOverview(this.medications, this.nextDose);

  final List<MyMedication> medications;
  final MedicationNextDose? nextDose;
}
