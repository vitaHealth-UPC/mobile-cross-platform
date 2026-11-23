import '../../../../shared/common/result/app_result.dart';
import '../../domain/entities/user_preferences.dart';
import '../ports/user_preferences_repository.dart';

/// Reconciles pending device changes with the backend.
final class SyncUserPreferences {
  const SyncUserPreferences(this._repository);
  final UserPreferencesRepository _repository;

  Future<AppResult<UserPreferences>> call(String userId) =>
      userId.trim().isEmpty
      ? Future.value(const AppFailure('INVALID_USER'))
      : _repository.sync(userId.trim());
}
