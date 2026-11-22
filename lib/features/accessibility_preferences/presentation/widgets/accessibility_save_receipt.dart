import 'package:flutter/material.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../application/readmodels/accessibility_change.dart';
import '../../domain/value_objects/accessibility_preferences.dart';

/// Confirms the field stored by an explicit edit; loading preferences is silent.
class AccessibilitySaveReceipt extends StatelessWidget {
  const AccessibilitySaveReceipt({
    super.key,
    required this.field,
    required this.preferences,
  });

  final AccessibilityField field;
  final AccessibilityPreferences preferences;

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final normal =
        Theme.of(context).brightness == Brightness.light &&
        !MediaQuery.highContrastOf(context);
    final label = switch (field) {
      AccessibilityField.textSize => text.pfTextSize,
      AccessibilityField.highContrast => text.pfHighContrast,
      AccessibilityField.darkTheme => text.pfDarkTheme,
      AccessibilityField.reducedMotion => text.pfReducedMotion,
      AccessibilityField.voiceConfirmation => text.pfVoiceConfirmation,
      AccessibilityField.readingAssistance => text.pfReadingAssistance,
    };
    final (title, detail) = switch (field) {
      AccessibilityField.highContrast when preferences.highContrast => (
        text.pfContrastActive,
        text.pfContrastApplied,
      ),
      AccessibilityField.reducedMotion when preferences.reducedMotion => (
        text.pfMotionReduced,
        text.pfMotionApplied,
      ),
      AccessibilityField.readingAssistance when preferences.readingAssistance =>
        (text.pfReadingActive, text.pfReadingApplied),
      _ => (text.pfAccessibilitySaved, text.pfAccessibilityReceipt(label)),
    };
    return Semantics(
      liveRegion: true,
      child: Container(
        key: const Key('accessibility-save-receipt'),
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(24, 4, 24, 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: normal ? const Color(0xFFE5F5E8) : colors.secondaryContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: normal
                    ? const Color(0xFF296B40)
                    : colors.onSecondaryContainer,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              detail,
              style: TextStyle(
                fontSize: 10,
                color: normal
                    ? const Color(0xFF637087)
                    : colors.onSecondaryContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
