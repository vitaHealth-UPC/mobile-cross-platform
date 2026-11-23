import '../../domain/value_objects/accessibility_preferences.dart';
import '../ports/application_language_store.dart';

/// Streams the local app language of one user.
final class ObserveApplicationLanguage {
  const ObserveApplicationLanguage(this._store);
  final ApplicationLanguageStore _store;

  Stream<AppLanguage> call(String userId) => _store.watch(userId);
}
