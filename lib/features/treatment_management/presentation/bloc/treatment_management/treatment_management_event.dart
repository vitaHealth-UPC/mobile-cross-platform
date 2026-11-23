/// Intents on an existing treatment: read, pause, resume, edit the regimen or change
/// the availability of its medication.
sealed class TreatmentManagementEvent {
  const TreatmentManagementEvent();
}

final class TreatmentManagementRequested extends TreatmentManagementEvent {
  const TreatmentManagementRequested();
}

final class TreatmentPauseRequested extends TreatmentManagementEvent {
  const TreatmentPauseRequested();
}

final class TreatmentResumeRequested extends TreatmentManagementEvent {
  const TreatmentResumeRequested();
}

/// Replaces the regimen; blank [delayMinutes] selects the system default follow-up.
final class RegimenEdited extends TreatmentManagementEvent {
  const RegimenEdited({
    required this.dose,
    required this.frequency,
    required this.scheduleText,
    required this.instructions,
    required this.delayMinutes,
  });
  final String dose;
  final String frequency;
  final String scheduleText;
  final String instructions;
  final String delayMinutes;
}

final class TreatmentMedicationReactivated extends TreatmentManagementEvent {
  const TreatmentMedicationReactivated();
}

final class TreatmentMedicationDeactivated extends TreatmentManagementEvent {
  const TreatmentMedicationDeactivated();
}
