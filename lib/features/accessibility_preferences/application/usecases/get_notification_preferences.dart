import '../../../../shared/common/result/app_result.dart';
import '../../domain/repositories/notification_preferences_repository.dart';
import '../../domain/value_objects/notification_preferences.dart';

/// Reads the notification preferences of one user.
final class GetNotificationPreferences {
  const GetNotificationPreferences(this._repository);
  final NotificationPreferencesRepository _repository;

  Future<AppResult<NotificationPreferences>> call(String userId) =>
      userId.trim().isEmpty
      ? Future.value(const AppFailure('INVALID_USER'))
      : _repository.get(userId.trim());
}
