/// Supported text-size choices and their proportional scaling factors.
enum TextSizeLevel {
  small('SMALL', 0.9),
  medium('MEDIUM', 1.0),
  large('LARGE', 1.15),
  extraLarge('EXTRA_LARGE', 1.3);

  const TextSizeLevel(this.wire, this.scaleFactor);

  /// Name used by the backend contract.
  final String wire;
  final double scaleFactor;

  static TextSizeLevel? fromWire(Object? value) {
    for (final level in values) {
      if (level.wire == value) return level;
    }
    return null;
  }
}

/// Device-applied accessibility values, independent of any storage mechanism.
final class AccessibilityPreferences {
  const AccessibilityPreferences({
    this.textSize = TextSizeLevel.medium,
    this.highContrast = false,
    this.reducedMotion = false,
    this.readingAssistance = false,
    this.voiceConfirmation = true,
    this.darkTheme = false,
  });

  static const defaults = AccessibilityPreferences();

  final TextSizeLevel textSize;
  final bool highContrast;
  final bool reducedMotion;
  final bool readingAssistance;
  final bool voiceConfirmation;
  final bool darkTheme;

  /// "Large text" is the single switch shown to the user; every size from large up counts.
  bool get largeTextEnabled => textSize.index >= TextSizeLevel.large.index;

  AccessibilityPreferences copyWith({
    TextSizeLevel? textSize,
    bool? highContrast,
    bool? reducedMotion,
    bool? readingAssistance,
    bool? voiceConfirmation,
    bool? darkTheme,
  }) => AccessibilityPreferences(
    textSize: textSize ?? this.textSize,
    highContrast: highContrast ?? this.highContrast,
    reducedMotion: reducedMotion ?? this.reducedMotion,
    readingAssistance: readingAssistance ?? this.readingAssistance,
    voiceConfirmation: voiceConfirmation ?? this.voiceConfirmation,
    darkTheme: darkTheme ?? this.darkTheme,
  );

  @override
  bool operator ==(Object other) =>
      other is AccessibilityPreferences &&
      textSize == other.textSize &&
      highContrast == other.highContrast &&
      reducedMotion == other.reducedMotion &&
      readingAssistance == other.readingAssistance &&
      voiceConfirmation == other.voiceConfirmation &&
      darkTheme == other.darkTheme;

  @override
  int get hashCode => Object.hash(
    textSize,
    highContrast,
    reducedMotion,
    readingAssistance,
    voiceConfirmation,
    darkTheme,
  );
}

/// The two localized experiences provided by this application.
enum AppLanguage {
  spanish('es-419', 'Español'),
  english('en', 'English');

  const AppLanguage(this.tag, this.displayName);
  final String tag;
  final String displayName;

  AppLanguage get next => this == spanish ? english : spanish;

  static AppLanguage fromTag(String? value) {
    for (final language in values) {
      if (language.tag == value) return language;
    }
    return spanish;
  }
}
