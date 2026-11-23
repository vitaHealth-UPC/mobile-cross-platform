import '../../../../shared/common/result/app_result.dart';
import '../ports/user_preferences_repository.dart';
import '../readmodels/accessibility_change.dart';

/// Applies one accessibility change on the device and sends it when possible.
final class UpdateAccessibility {
  const UpdateAccessibility(this._repository);
  final UserPreferencesRepository _repository;

  Future<AppResult<PreferenceUpdate>> call(
    String userId,
    AccessibilityChange change,
  ) => userId.trim().isEmpty
      ? Future.value(const AppFailure('INVALID_USER'))
      : _repository.update(userId.trim(), change);
}
