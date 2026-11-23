import '../../../../shared/common/result/app_result.dart';
import '../../domain/value_objects/administration_schedule.dart';
import '../../domain/value_objects/regimen_text.dart';

/// Validated dose and frequency selected together in the regimen wizard.
final class RegimenBasics {
  const RegimenBasics(this.dose, this.frequency);
  final Dosage dose;
  final Frequency frequency;
}

/// Validated local administration times paired with their instructions.
final class ScheduleInstructions {
  const ScheduleInstructions(this.schedule, this.instructions);
  final AdministrationSchedule schedule;
  final AdministrationInstructions instructions;
}

/// Parses dose and frequency into the values used by the regimen wizard.
final class SetDoseFrequency {
  const SetDoseFrequency();

  AppResult<RegimenBasics> call(String dose, String frequency) {
    final parsedDose = Dosage.tryParse(dose);
    if (parsedDose == null) return const AppFailure('INVALID_DOSAGE');
    final parsedFrequency = Frequency.tryParse(frequency);
    if (parsedFrequency == null) return const AppFailure('INVALID_FREQUENCY');
    return AppSuccess(RegimenBasics(parsedDose, parsedFrequency));
  }
}

/// Validates explicit local administration times, separated by commas, and instructions.
final class SetScheduleInstructions {
  const SetScheduleInstructions();

  AppResult<ScheduleInstructions> call(
    String scheduleText,
    String instructions,
  ) {
    final tokens = scheduleText
        .split(',')
        .map((token) => token.trim())
        .where((token) => token.isNotEmpty)
        .toList();
    if (tokens.isEmpty) return const AppFailure('EMPTY_SCHEDULE');
    final times = <ClockTime>[];
    for (final token in tokens) {
      final time = ClockTime.tryParse(token);
      if (time == null) return const AppFailure('INVALID_SCHEDULE_TIME');
      times.add(time);
    }
    final schedule = AdministrationSchedule.create(times);
    if (schedule == null) return const AppFailure('EMPTY_SCHEDULE');
    final parsed = AdministrationInstructions.tryParse(instructions);
    if (parsed == null) return const AppFailure('INSTRUCTIONS_TOO_LONG');
    return AppSuccess(ScheduleInstructions(schedule, parsed));
  }
}

/// Validates the follow-up interval selected in the reminder step.
final class SetReminderPolicy {
  const SetReminderPolicy();

  AppResult<ReminderDelayMinutes> call(String followUpDelayMinutes) {
    final delay = ReminderDelayMinutes.tryParse(followUpDelayMinutes);
    return delay == null
        ? const AppFailure('INVALID_REMINDER_DELAY')
        : AppSuccess(delay);
  }
}
