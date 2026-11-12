import 'administration_schedule.dart';
import 'regimen_text.dart';

/// Complete regimen accepted by the server: dose, frequency, schedule and reminders.
final class TreatmentRegimen {
  const TreatmentRegimen({
    required this.dose,
    required this.frequency,
    required this.schedule,
    required this.instructions,
    this.reminderLeadMinutes = 0,
    this.followUpDelay,
  });

  final Dosage dose;
  final Frequency frequency;
  final AdministrationSchedule schedule;
  final AdministrationInstructions instructions;

  /// Minutes before the dose; the wizard never sets it, edits preserve it.
  final int reminderLeadMinutes;

  /// Null means the system default follow-up is used.
  final ReminderDelayMinutes? followUpDelay;
}
