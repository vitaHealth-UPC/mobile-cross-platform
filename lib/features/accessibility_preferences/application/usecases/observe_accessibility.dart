import '../../domain/value_objects/accessibility_preferences.dart';
import '../ports/user_preferences_repository.dart';

/// Streams the device copy of the accessibility preferences of one user.
final class ObserveAccessibility {
  const ObserveAccessibility(this._repository);
  final UserPreferencesRepository _repository;

  Stream<AccessibilityPreferences> call(String userId) =>
      _repository.watch(userId);
}
