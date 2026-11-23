import '../../../../shared/common/result/app_result.dart';
import '../../domain/value_objects/regimen_text.dart';

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
