import 'package:flutter/material.dart';

import '../../../../shared/presentation/theme/tata_theme.dart';
import '../../domain/value_objects/accessibility_preferences.dart';

/// Translates accessibility preferences into what Flutter renders.
abstract final class Appearance {
  static ThemeData themeFor(AccessibilityPreferences preferences) {
    final base = switch ((preferences.darkTheme, preferences.highContrast)) {
      (false, false) => TataTheme.light,
      (true, false) => TataTheme.dark,
      (false, true) => TataTheme.lightHighContrast,
      (true, true) => TataTheme.darkHighContrast,
    };
    if (!preferences.readingAssistance) return base;
    // Reading assistance: looser lines and letters on body text.
    return base.copyWith(
      textTheme: base.textTheme.copyWith(
        bodyLarge: base.textTheme.bodyLarge?.copyWith(
          height: 1.7,
          letterSpacing: 0.4,
        ),
        bodyMedium: base.textTheme.bodyMedium?.copyWith(
          height: 1.7,
          letterSpacing: 0.4,
        ),
        bodySmall: base.textTheme.bodySmall?.copyWith(
          height: 1.7,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  /// Locale for a language choice; the ARB files provide `es` and `en`.
  static Locale localeFor(AppLanguage language) => switch (language) {
    AppLanguage.spanish => const Locale('es'),
    AppLanguage.english => const Locale('en'),
  };

  /// Applies text scale and motion preferences on top of the platform's own settings:
  /// the user's factor multiplies the system scale, so neither choice is ignored.
  static Widget wrap(
    BuildContext context,
    AccessibilityPreferences value,
    Widget child,
  ) {
    final media = MediaQuery.of(context);
    return MediaQuery(
      data: media.copyWith(
        textScaler: TextScaler.linear(
          media.textScaler.scale(1) * value.textSize.scaleFactor,
        ),
        disableAnimations: media.disableAnimations || value.reducedMotion,
      ),
      child: child,
    );
  }
}
