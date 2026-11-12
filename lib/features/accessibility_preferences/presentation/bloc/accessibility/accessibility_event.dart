import '../../../application/readmodels/accessibility_change.dart';

/// Intents of the accessibility screen.
sealed class AccessibilityEvent {
  const AccessibilityEvent();
}

/// Starts following the device copy and reconciles it with the server.
final class AccessibilityStarted extends AccessibilityEvent {
  const AccessibilityStarted();
}

final class AccessibilityChanged extends AccessibilityEvent {
  const AccessibilityChanged(this.change);
  final AccessibilityChange change;
}

/// Switches between the Spanish and English experiences.
final class LanguageToggled extends AccessibilityEvent {
  const LanguageToggled();
}

/// Retries sending changes that did not reach the server.
final class AccessibilitySyncRequested extends AccessibilityEvent {
  const AccessibilitySyncRequested();
}
