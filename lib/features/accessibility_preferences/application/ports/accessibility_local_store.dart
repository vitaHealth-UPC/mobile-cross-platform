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
