import '../../../../shared/common/result/app_result.dart';
import '../../domain/value_objects/administration_schedule.dart';
import '../../domain/value_objects/regimen_text.dart';

/// Validated local administration times paired with their instructions.
final class ScheduleInstructions {
  const ScheduleInstructions(this.schedule, this.instructions);
  final AdministrationSchedule schedule;
  final AdministrationInstructions instructions;
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
