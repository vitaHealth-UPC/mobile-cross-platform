import '../../../../shared/common/result/app_result.dart';
import '../../domain/entities/user_preferences.dart';
import '../../domain/value_objects/accessibility_preferences.dart';
import '../readmodels/accessibility_change.dart';

/// Coordinates account preferences with the device copy and pending synchronization.
abstract interface class UserPreferencesRepository {
  Stream<AccessibilityPreferences> watch(String userId);

  /// Sends changes that could not reach the backend, then replaces the local copy with
  /// the server's.
  Future<AppResult<UserPreferences>> sync(String userId);

  Future<AppResult<PreferenceUpdate>> update(
    String userId,
    AccessibilityChange change,
  );
}
