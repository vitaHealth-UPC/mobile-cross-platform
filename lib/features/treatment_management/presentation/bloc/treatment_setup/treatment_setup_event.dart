/// Intents of the treatment wizard: data, regimen, schedule, reminders and review.
sealed class TreatmentSetupEvent {
  const TreatmentSetupEvent();
}

/// Creates the named draft for the medication chosen before the wizard.
final class TreatmentDraftSubmitted extends TreatmentSetupEvent {
  const TreatmentDraftSubmitted(this.name);
  final String name;
}

final class RegimenBasicsSubmitted extends TreatmentSetupEvent {
  const RegimenBasicsSubmitted(this.dose, this.frequency);
  final String dose;
  final String frequency;
}

final class ScheduleSubmitted extends TreatmentSetupEvent {
  const ScheduleSubmitted(this.scheduleText, this.instructions);
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

/// Saves the regimen and activates the treatment.
final class TreatmentActivationRequested extends TreatmentSetupEvent {
  const TreatmentActivationRequested();
}

/// Revisits the regimen after the server rejected its configuration, preserving the draft.
final class TreatmentConfigurationCorrectionRequested
    extends TreatmentSetupEvent {
  const TreatmentConfigurationCorrectionRequested();
}
