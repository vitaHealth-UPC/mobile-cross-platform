import '../../../../shared/common/result/app_result.dart';
import '../../domain/value_objects/accessibility_preferences.dart';
import '../ports/application_language_store.dart';

/// Stores the app language for the signed-in user on this device.
final class ChangeApplicationLanguage {
  const ChangeApplicationLanguage(this._store);
  final ApplicationLanguageStore _store;

  Future<AppResult<AppLanguage>> call(
    String userId,
    AppLanguage language,
  ) async {
    if (userId.trim().isEmpty) return const AppFailure('INVALID_USER');
    try {
      await _store.write(userId.trim(), language);
      return AppSuccess(language);
    } on Exception {
      return const AppFailure('LOCAL_WRITE_FAILED');
    }
  }
}
