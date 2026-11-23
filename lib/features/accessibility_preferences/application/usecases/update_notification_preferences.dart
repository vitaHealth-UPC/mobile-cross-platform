import '../../../../shared/common/result/app_result.dart';
import '../../domain/repositories/notification_preferences_repository.dart';
import '../../domain/value_objects/notification_preferences.dart';

/// Replaces quiet hours and channels together.
final class UpdateNotificationPreferences {
  const UpdateNotificationPreferences(this._repository);
  final NotificationPreferencesRepository _repository;

  Future<AppResult<NotificationPreferences>> call(
    String userId,
    NotificationPreferences preferences,
  ) => userId.trim().isEmpty
      ? Future.value(const AppFailure('INVALID_USER'))
      : _repository.update(userId.trim(), preferences);
}
