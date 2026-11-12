import '../../../../shared/common/result/app_result.dart';
import '../value_objects/notification_preferences.dart';

/// Quiet hours, channels, delivery policy and recipients. The backend uses them when it
/// sends notices, so there is no device copy.
abstract interface class NotificationPreferencesRepository {
  Future<AppResult<NotificationPreferences>> get(String userId);

  /// The backend replaces quiet hours and channels together.
  Future<AppResult<NotificationPreferences>> update(
    String userId,
    NotificationPreferences preferences,
  );

  /// Changes delivery policy and recipients without replacing quiet hours or channels.
  Future<AppResult<NotificationPreferences>> updatePolicy(
    String userId,
    NotificationPolicy policy,
    List<EmergencyContact> contacts,
  );
}
