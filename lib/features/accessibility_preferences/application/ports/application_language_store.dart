import '../../domain/value_objects/accessibility_preferences.dart';

/// Owner-partitioned local app language. No health data or credentials are stored.
abstract interface class ApplicationLanguageStore {
  Stream<AppLanguage> watch(String ownerId);

  Future<void> write(String ownerId, AppLanguage language);
}
