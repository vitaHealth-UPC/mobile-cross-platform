import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/accessibility/accessibility_bloc.dart';
import '../bloc/accessibility/accessibility_event.dart';
import '../bloc/notifications/notification_preferences_bloc.dart';
import '../bloc/notifications/notification_preferences_event.dart';
import '../screens/accessibility_screen.dart';
import '../screens/notification_preferences_screen.dart';

/// Builders for the blocs of the Accessibility & Preferences flows.
final class PreferencesFactories {
  const PreferencesFactories({
    required this.createAccessibilityBloc,
    required this.createNotificationsBloc,
  });

  final AccessibilityBloc Function(String userId) createAccessibilityBloc;
  final NotificationPreferencesBloc Function(String userId)
  createNotificationsBloc;
}

/// Opens the preferences screens of the signed-in user.
final class PreferencesNavigation {
  const PreferencesNavigation(this._factories);
  final PreferencesFactories _factories;

  Future<void> openAccessibility(BuildContext context, String userId) =>
      Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (_) =>
                _factories.createAccessibilityBloc(userId)
                  ..add(const AccessibilityStarted()),
            child: const AccessibilityScreen(),
          ),
        ),
      );

  Future<void> openNotifications(
    BuildContext context,
    String userId,
    VoidCallback onSessionInvalidated,
  ) => Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (_) => BlocProvider(
        create: (_) =>
            _factories.createNotificationsBloc(userId)
              ..add(const NotificationPreferencesRequested()),
        child: Builder(
          builder: (innerContext) => NotificationPreferencesScreen(
            onSessionInvalidated: () {
              Navigator.of(innerContext).popUntil((route) => route.isFirst);
              onSessionInvalidated();
            },
          ),
        ),
      ),
    ),
  );
}
