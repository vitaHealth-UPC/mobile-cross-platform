import '../../../../shared/common/result/app_result.dart';
import '../../domain/entities/treatment.dart';
import '../../domain/repositories/treatment_lifecycle_repository.dart';
import '../../domain/value_objects/administration_schedule.dart';
import '../../domain/value_objects/regimen_text.dart';
import '../../domain/value_objects/treatment_regimen.dart';

/// Regimen text exactly as the caregiver wrote it, before validation.
final class RegimenDraft {
  const RegimenDraft({
    required this.dose,
    required this.frequency,
    required this.scheduleText,
    required this.instructions,
    this.followUpDelayMinutes,
    this.reminderLeadMinutes = 0,
    this.recurrenceZone,
    this.recurrenceMode,
    this.recurrenceAnchor,
  });

  final String dose;
  final String frequency;

  /// Comma separated `HH:mm` times.
  final String scheduleText;
  final String instructions;

  /// Null selects the system default follow-up.
  final int? followUpDelayMinutes;
  final int reminderLeadMinutes;
  final String? recurrenceZone;
  final String? recurrenceMode;
  final DateTime? recurrenceAnchor;
}

/// Validates a complete regimen with the same values used by the wizard, then saves it.
final class ConfigureTreatment {
  const ConfigureTreatment(this._repository);
  final TreatmentLifecycleRepository _repository;

  Future<AppResult<Treatment>> call(
    String treatmentId,
    String medicationId,
    RegimenDraft draft,
  ) {
    final dose = Dosage.tryParse(draft.dose);
    final frequency = Frequency.tryParse(draft.frequency);
    final instructions = AdministrationInstructions.tryParse(
      draft.instructions,
    );
    final times = draft.scheduleText
        .split(',')
        .map((token) => token.trim())
        .where((token) => token.isNotEmpty)
        .map(ClockTime.tryParse)
        .toList();
    final schedule = times.contains(null)
        ? null
        : AdministrationSchedule.create(times.whereType<ClockTime>());
    final delay = draft.followUpDelayMinutes;
    final lead = draft.reminderLeadMinutes;
    if (treatmentId.trim().isEmpty ||
        medicationId.trim().isEmpty ||
        dose == null ||
        frequency == null ||
        instructions == null ||
        schedule == null ||
        (draft.recurrenceMode != null && draft.recurrenceZone == null) ||
        (draft.recurrenceAnchor != null &&
            draft.recurrenceMode != 'FIXED_INTERVAL') ||
        (draft.recurrenceMode == 'FIXED_INTERVAL' &&
            draft.recurrenceAnchor == null) ||
        (draft.recurrenceMode != null &&
            draft.recurrenceMode != 'LOCAL_TIMES' &&
            draft.recurrenceMode != 'FIXED_INTERVAL') ||
        lead < 0 ||
        lead > 1440 ||
        (delay != null && (delay < 0 || delay > 1440))) {
      return Future.value(const AppFailure('INVALID_TREATMENT_CONFIGURATION'));
    }
    if (!frequency.matchesMinutes(
      schedule.times.map((t) => t.hour * 60 + t.minute),
    )) {
      return Future.value(const AppFailure('SCHEDULE_FREQUENCY_MISMATCH'));
    }
    return _repository.configure(
      treatmentId.trim(),
      medicationId.trim(),
      TreatmentRegimen(
        dose: dose,
        frequency: frequency,
        schedule: schedule,
        instructions: instructions,
        reminderLeadMinutes: lead,
        recurrenceZone: draft.recurrenceZone,
        recurrenceMode: draft.recurrenceMode,
        recurrenceAnchor: draft.recurrenceAnchor,
        followUpDelay: delay == null
            ? null
            : ReminderDelayMinutes.tryParse('$delay'),
      ),
    );
  }
}
