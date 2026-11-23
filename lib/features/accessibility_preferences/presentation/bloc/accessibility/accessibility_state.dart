import '../../../application/readmodels/accessibility_change.dart';
import '../../../domain/value_objects/accessibility_preferences.dart';

/// Whether the visible values are known to be stored in the account.
enum AccessibilitySyncStatus { unknown, synced, pending }

final class AccessibilityState {
  const AccessibilityState({
    this.accessibility = AccessibilityPreferences.defaults,
    this.language = AppLanguage.spanish,
    this.sync = AccessibilitySyncStatus.unknown,
    this.errorCode,
    this.receipt,
  });

  final AccessibilityPreferences accessibility;
  final AppLanguage language;
  final AccessibilitySyncStatus sync;
  final String? errorCode;

  /// The field acknowledged by the latest completed edit, never an initial read.
  final AccessibilityField? receipt;

  AccessibilityState copyWith({
    AccessibilityPreferences? accessibility,
    AppLanguage? language,
    AccessibilitySyncStatus? sync,
    String? errorCode,
    AccessibilityField? receipt,
    bool clearReceipt = false,
  }) => AccessibilityState(
    accessibility: accessibility ?? this.accessibility,
    language: language ?? this.language,
    sync: sync ?? this.sync,
    errorCode: errorCode,
    receipt: clearReceipt ? null : receipt ?? this.receipt,
  );
}
