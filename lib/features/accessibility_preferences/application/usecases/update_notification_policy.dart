import '../../../../shared/common/result/app_result.dart';
import '../../domain/repositories/notification_preferences_repository.dart';
import '../../domain/value_objects/notification_preferences.dart';

/// Replaces the delivery policy and the emergency contacts.
final class UpdateNotificationPolicy {
  const UpdateNotificationPolicy(this._repository);
  final NotificationPreferencesRepository _repository;

  Future<AppResult<NotificationPreferences>> call(
    String userId,
    NotificationPolicy policy,
    List<EmergencyContact> contacts,
  ) {
    final phones = contacts.map((c) => c.phone.replaceFirst('+', '')).toSet();
    if (userId.trim().isEmpty ||
        contacts.length > 5 ||
        phones.length != contacts.length) {
      return Future.value(const AppFailure('REQUEST_VALIDATION_FAILED'));
    }
    return _repository.updatePolicy(userId.trim(), policy, contacts);
  }
}
