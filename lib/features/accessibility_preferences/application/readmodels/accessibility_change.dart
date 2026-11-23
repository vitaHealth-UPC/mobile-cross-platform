import '../../domain/value_objects/accessibility_preferences.dart';

/// Independently synchronized accessibility fields; names are stable persistence keys.
enum AccessibilityField {
  textSize,
  highContrast,
  darkTheme,
  reducedMotion,
  voiceConfirmation,
  readingAssistance,
}

/// One requested change to a single accessibility field.
sealed class AccessibilityChange {
  const AccessibilityChange();

  AccessibilityField get field;

  /// Returns [preferences] with this change applied.
  AccessibilityPreferences applyTo(AccessibilityPreferences preferences);

  /// The change that sets [field] to the value it has in [preferences].
  static AccessibilityChange forField(
    AccessibilityField field,
    AccessibilityPreferences preferences,
  ) => switch (field) {
    AccessibilityField.textSize => TextSizeChange(preferences.textSize),
    AccessibilityField.highContrast => HighContrastChange(
      preferences.highContrast,
    ),
    AccessibilityField.darkTheme => DarkThemeChange(preferences.darkTheme),
    AccessibilityField.reducedMotion => ReducedMotionChange(
      preferences.reducedMotion,
    ),
    AccessibilityField.voiceConfirmation => VoiceConfirmationChange(
      preferences.voiceConfirmation,
    ),
    AccessibilityField.readingAssistance => ReadingAssistanceChange(
      preferences.readingAssistance,
    ),
  };

  /// Copies [source] into [target] for [fields] only; other fields keep [target]'s value.
  static AccessibilityPreferences merge(
    AccessibilityPreferences target,
    AccessibilityPreferences source,
    Set<AccessibilityField> fields,
  ) {
    var merged = target;
    for (final field in fields) {
      merged = forField(field, source).applyTo(merged);
    }
    return merged;
  }
}

final class TextSizeChange extends AccessibilityChange {
  const TextSizeChange(this.value);
  final TextSizeLevel value;
  @override
  AccessibilityField get field => AccessibilityField.textSize;
  @override
  AccessibilityPreferences applyTo(AccessibilityPreferences p) =>
      p.copyWith(textSize: value);
}

final class HighContrastChange extends AccessibilityChange {
  const HighContrastChange(this.value);
  final bool value;
  @override
  AccessibilityField get field => AccessibilityField.highContrast;
  @override
  AccessibilityPreferences applyTo(AccessibilityPreferences p) =>
      p.copyWith(highContrast: value);
}

final class DarkThemeChange extends AccessibilityChange {
  const DarkThemeChange(this.value);
  final bool value;
  @override
  AccessibilityField get field => AccessibilityField.darkTheme;
  @override
  AccessibilityPreferences applyTo(AccessibilityPreferences p) =>
      p.copyWith(darkTheme: value);
}

final class ReducedMotionChange extends AccessibilityChange {
  const ReducedMotionChange(this.value);
  final bool value;
  @override
  AccessibilityField get field => AccessibilityField.reducedMotion;
  @override
  AccessibilityPreferences applyTo(AccessibilityPreferences p) =>
      p.copyWith(reducedMotion: value);
}

final class VoiceConfirmationChange extends AccessibilityChange {
  const VoiceConfirmationChange(this.value);
  final bool value;
  @override
  AccessibilityField get field => AccessibilityField.voiceConfirmation;
  @override
  AccessibilityPreferences applyTo(AccessibilityPreferences p) =>
      p.copyWith(voiceConfirmation: value);
}

final class ReadingAssistanceChange extends AccessibilityChange {
  const ReadingAssistanceChange(this.value);
  final bool value;
  @override
  AccessibilityField get field => AccessibilityField.readingAssistance;
  @override
  AccessibilityPreferences applyTo(AccessibilityPreferences p) =>
      p.copyWith(readingAssistance: value);
}

/// Result of changing a preference. The value is always kept on the device;
/// [syncedWithServer] is false when the backend could not be reached yet.
final class PreferenceUpdate {
  const PreferenceUpdate(this.accessibility, {required this.syncedWithServer});
  final AccessibilityPreferences accessibility;
  final bool syncedWithServer;
}
