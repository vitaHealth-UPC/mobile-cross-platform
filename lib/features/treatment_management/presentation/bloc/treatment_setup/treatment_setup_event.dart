import 'treatment_setup_state.dart';

/// Intents of the treatment wizard: data, regimen, reminders and review.
sealed class TreatmentSetupEvent {
  const TreatmentSetupEvent();
}

/// Confirms the treatment name and its medications; nothing reaches the
/// server until activation.
final class TreatmentDraftSubmitted extends TreatmentSetupEvent {
  const TreatmentDraftSubmitted(this.name);
  final String name;
}

/// Replaces the medications of the treatment (one or more).
final class TreatmentMedicationsChanged extends TreatmentSetupEvent {
  const TreatmentMedicationsChanged(this.medications);
  final List<SetupMedication> medications;
}

/// Regimen text typed for one medication.
final class RegimenInput {
  const RegimenInput(
    this.dose,
    this.frequency,
    this.scheduleText,
    this.instructions,
  );
  final String dose;
  final String frequency;
  final String scheduleText;
  final String instructions;
}

/// Validates the regimen of every medication in one step.
final class TreatmentRegimensSubmitted extends TreatmentSetupEvent {
  const TreatmentRegimensSubmitted(this.regimens);

  /// Regimen by medication id.
  final Map<String, RegimenInput> regimens;
}

/// First half of the two-step regimen of a single medication: dose and
/// frequency, checked before the times are chosen.
final class RegimenBasicsSubmitted extends TreatmentSetupEvent {
  const RegimenBasicsSubmitted(this.dose, this.frequency);
  final String dose;
  final String frequency;
}

/// Second half of the two-step regimen of a single medication.
final class ScheduleSubmitted extends TreatmentSetupEvent {
  const ScheduleSubmitted(this.scheduleText, this.instructions);
  final String scheduleText;
  final String instructions;
}

/// Validates the complete prescription of a single-medication treatment.
final class TreatmentRegimenSubmitted extends TreatmentSetupEvent {
  const TreatmentRegimenSubmitted(
    this.dose,
    this.frequency,
    this.scheduleText,
    this.instructions,
  );
  final String dose;
  final String frequency;
  final String scheduleText;
  final String instructions;
}

final class ReminderSubmitted extends TreatmentSetupEvent {
  const ReminderSubmitted(this.delayMinutes);
  final String delayMinutes;
}

/// Goes back one step without discarding what was already validated.
final class TreatmentSetupBackRequested extends TreatmentSetupEvent {
  const TreatmentSetupBackRequested();
}

/// Creates the drafts, saves every regimen and activates the treatment.
final class TreatmentActivationRequested extends TreatmentSetupEvent {
  const TreatmentActivationRequested();
}

/// Revisits the regimen after the server rejected its configuration, preserving the drafts.
final class TreatmentConfigurationCorrectionRequested
    extends TreatmentSetupEvent {
  const TreatmentConfigurationCorrectionRequested();
}
