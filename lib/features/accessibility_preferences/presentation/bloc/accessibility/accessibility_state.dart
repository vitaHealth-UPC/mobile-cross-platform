import '../../../domain/value_objects/accessibility_preferences.dart';

/// Whether the visible values are known to be stored in the account.
enum AccessibilitySyncStatus { unknown, synced, pending }

final class AccessibilityState {
  const AccessibilityState({
    this.accessibility = AccessibilityPreferences.defaults,
    this.language = AppLanguage.spanish,
    this.sync = AccessibilitySyncStatus.unknown,
    this.errorCode,
  });

  final AccessibilityPreferences accessibility;
  final AppLanguage language;
  final AccessibilitySyncStatus sync;
  final String? errorCode;

  AccessibilityState copyWith({
    AccessibilityPreferences? accessibility,
    AppLanguage? language,
    AccessibilitySyncStatus? sync,
    String? errorCode,
  }) => AccessibilityState(
    accessibility: accessibility ?? this.accessibility,
    language: language ?? this.language,
    sync: sync ?? this.sync,
    errorCode: errorCode,
  );
}
