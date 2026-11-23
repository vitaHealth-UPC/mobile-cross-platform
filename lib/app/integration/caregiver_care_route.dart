import 'package:flutter/material.dart';

import '../../features/accessibility_preferences/presentation/navigation/preferences_navigation.dart';
import '../../features/care_link/application/readmodels/caregiver_link_summary.dart';
import '../../features/treatment_management/presentation/navigation/treatment_navigation.dart';
import '../../l10n/generated/app_localizations.dart';

/// Care area of one confirmed profile: treatments and medications of the older adult.
class CaregiverCareRoute extends StatelessWidget {
  const CaregiverCareRoute({
    super.key,
    required this.profile,
    required this.treatments,
    required this.onOpenAdherence,
    required this.onSessionInvalidated,
  });

  final CaregiverLinkSummary profile;
  final TreatmentNavigation treatments;

  /// Opens the adherence history of this person; owned by the host.
  final void Function(BuildContext context) onOpenAdherence;
  final VoidCallback onSessionInvalidated;

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(profile.fullName)),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.insights_outlined),
            title: Text(text.adherenceHistoryTitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => onOpenAdherence(context),
          ),
          ListTile(
            leading: const Icon(Icons.assignment_outlined),
            title: Text(text.tmTreatmentsTitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => treatments.openTreatments(
              context,
              profile.olderAdultId,
              onSessionInvalidated,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.medication_outlined),
            title: Text(text.tmMedicationsTitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => treatments.openMedications(
              context,
              profile.olderAdultId,
              onSessionInvalidated,
            ),
          ),
        ],
      ),
    );
  }
}

/// The caregiver's own settings: notification delivery and accessibility.
class CaregiverSettingsRoute extends StatelessWidget {
  const CaregiverSettingsRoute({
    super.key,
    required this.caregiverId,
    required this.preferences,
    required this.onSessionInvalidated,
  });

  final String caregiverId;
  final PreferencesNavigation preferences;
  final VoidCallback onSessionInvalidated;

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(text.pfSettings)),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: Text(text.pfNotificationsTitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => preferences.openNotifications(
              context,
              caregiverId,
              onSessionInvalidated,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.accessibility_new),
            title: Text(text.pfAccessibilityTitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => preferences.openAccessibility(context, caregiverId),
          ),
        ],
      ),
    );
  }
}
