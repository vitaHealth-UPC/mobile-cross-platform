import '../../../../shared/common/result/app_result.dart';
import '../../domain/entities/user_preferences.dart';
import '../../domain/value_objects/accessibility_preferences.dart';
import '../readmodels/accessibility_change.dart';

/// Device copy of the accessibility preferences, so they apply before any network call
/// finishes. Every call is partitioned by the owner of the session.
abstract interface class AccessibilityLocalStore {
  /// Emits the current value on listen and again after every save for [ownerId].
  Stream<AccessibilityPreferences> watch(String ownerId);

  Future<AccessibilityPreferences> current(String ownerId);

  /// Writes values and the exact unacknowledged field set together.
  Future<void> save(
    String ownerId,
    AccessibilityPreferences preferences,
    Set<AccessibilityField> pending,
  );

  Future<Set<AccessibilityField>> pending(String ownerId);
}

/// Owner-partitioned local app language. No health data or credentials are stored.
abstract interface class ApplicationLanguageStore {
  Stream<AppLanguage> watch(String ownerId);

  Future<void> write(String ownerId, AppLanguage language);
}

/// Backend contract of `/api/v1/users/{userId}/preferences`.
abstract interface class UserPreferencesRemote {
  Future<AppResult<UserPreferences>> get(String userId);

  /// Sends one accessibility field and returns the stored snapshot.
  Future<AppResult<UserPreferences>> update(
    String userId,
    AccessibilityChange change,
  );
}

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
