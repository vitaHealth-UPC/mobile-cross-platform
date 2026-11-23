import '../../../../shared/common/result/app_result.dart';
import '../../domain/entities/user_preferences.dart';
import '../../domain/repositories/notification_preferences_repository.dart';
import '../../domain/value_objects/accessibility_preferences.dart';
import '../../domain/value_objects/notification_preferences.dart';
import '../ports/preferences_ports.dart';
import '../readmodels/accessibility_change.dart';

bool _blank(String value) => value.trim().isEmpty;

/// Streams the device copy of the accessibility preferences of one user.
final class ObserveAccessibility {
  const ObserveAccessibility(this._repository);
  final UserPreferencesRepository _repository;

  Stream<AccessibilityPreferences> call(String userId) =>
      _repository.watch(userId);
}

/// Streams the local app language of one user.
final class ObserveApplicationLanguage {
  const ObserveApplicationLanguage(this._store);
  final ApplicationLanguageStore _store;

  Stream<AppLanguage> call(String userId) => _store.watch(userId);
}

/// Reconciles pending device changes with the backend.
final class SyncUserPreferences {
  const SyncUserPreferences(this._repository);
  final UserPreferencesRepository _repository;

  Future<AppResult<UserPreferences>> call(String userId) => _blank(userId)
      ? Future.value(const AppFailure('INVALID_USER'))
      : _repository.sync(userId.trim());
}

/// Applies one accessibility change on the device and sends it when possible.
final class UpdateAccessibility {
  const UpdateAccessibility(this._repository);
  final UserPreferencesRepository _repository;

  Future<AppResult<PreferenceUpdate>> call(
    String userId,
    AccessibilityChange change,
  ) => _blank(userId)
      ? Future.value(const AppFailure('INVALID_USER'))
      : _repository.update(userId.trim(), change);
}

/// Stores the app language for the signed-in user on this device.
final class ChangeApplicationLanguage {
  const ChangeApplicationLanguage(this._store);
  final ApplicationLanguageStore _store;

  Future<AppResult<AppLanguage>> call(
    String userId,
    AppLanguage language,
  ) async {
    if (_blank(userId)) return const AppFailure('INVALID_USER');
    try {
      await _store.write(userId.trim(), language);
      return AppSuccess(language);
    } on Exception {
      return const AppFailure('LOCAL_WRITE_FAILED');
    }
  }
}

/// Reads the notification preferences of one user.
final class GetNotificationPreferences {
  const GetNotificationPreferences(this._repository);
  final NotificationPreferencesRepository _repository;

  Future<AppResult<NotificationPreferences>> call(String userId) =>
      _blank(userId)
      ? Future.value(const AppFailure('INVALID_USER'))
      : _repository.get(userId.trim());
}

/// Replaces quiet hours and channels together.
final class UpdateNotificationPreferences {
  const UpdateNotificationPreferences(this._repository);
  final NotificationPreferencesRepository _repository;

  Future<AppResult<NotificationPreferences>> call(
    String userId,
    NotificationPreferences preferences,
  ) => _blank(userId)
      ? Future.value(const AppFailure('INVALID_USER'))
      : _repository.update(userId.trim(), preferences);
}

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
    if (_blank(userId) ||
        contacts.length > 5 ||
        phones.length != contacts.length) {
      return Future.value(const AppFailure('REQUEST_VALIDATION_FAILED'));
    }
    return _repository.updatePolicy(userId.trim(), policy, contacts);
  }
}
