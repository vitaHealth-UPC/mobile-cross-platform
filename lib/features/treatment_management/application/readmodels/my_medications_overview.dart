import 'treatment_detail.dart';

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
    this.treatments = const [],
  });

  final String id;
  final String name;
  final String presentation;

  /// All configured regimens returned with this medication.
  final List<TreatmentDetail> treatments;

  /// True only when the medication is available and one of its treatments is active.
  final bool active;
  final String dose;
  final String instructions;
  final List<String> scheduledTimes;

  /// Instructions when present, otherwise the scheduled times.
  String get scheduleLabel =>
      instructions.trim().isNotEmpty ? instructions : scheduledTimes.join(', ');

  @override
  String toString() => 'MyMedication[clinicalData=REDACTED]';
}

/// Next scheduled intake, identified by the medication it belongs to.
final class MedicationNextDose {
  const MedicationNextDose({
    required this.intakeId,
    required this.medicationName,
    this.medicationId,
    required this.scheduledAt,
  });

  final String intakeId;
  final String medicationName;

  /// Server reference; legacy cached intake snapshots may not carry it.
  final String? medicationId;

  /// UTC instant; presentation converts it to the device time zone.
  final DateTime scheduledAt;
}

/// Medication catalog paired with the next intake available for the same adult.
final class MyMedicationsOverview {
  const MyMedicationsOverview(
    this.medications,
    this.nextDose, {
    this.scheduleError,
  });

  final List<MyMedication> medications;
  final MedicationNextDose? nextDose;
  final String? scheduleError;
}
