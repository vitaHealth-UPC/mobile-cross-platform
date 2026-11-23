import '../../../../shared/common/result/app_result.dart';
import '../../domain/entities/user_preferences.dart';
import '../readmodels/accessibility_change.dart';

/// Backend contract of `/api/v1/users/{userId}/preferences`.
abstract interface class UserPreferencesRemote {
  Future<AppResult<UserPreferences>> get(String userId);

  /// Sends one accessibility field and returns the stored snapshot.
  Future<AppResult<UserPreferences>> update(
    String userId,
    AccessibilityChange change,
  );
}
