import '../value_objects/accessibility_preferences.dart';
import '../value_objects/notification_preferences.dart';

/// Configuration belonging to one user, grouping accessibility and delivery preferences.
final class UserPreferences {
  UserPreferences({
    required this.userId,
    required this.accessibility,
    required this.notifications,
  }) {
    if (userId.trim().isEmpty) {
      throw ArgumentError('Preferences must belong to one user');
    }
  }

  final String userId;
  final AccessibilityPreferences accessibility;
  final NotificationPreferences notifications;
}
