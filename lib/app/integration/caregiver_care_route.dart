import 'package:flutter/material.dart';

import '../../features/accessibility_preferences/presentation/navigation/preferences_navigation.dart';
import '../../features/adherence_analytics/presentation/bloc/level/level_bloc.dart';
import '../../features/adherence_analytics/presentation/navigation/adherence_badge_view.dart';
import '../../features/adherence_analytics/presentation/navigation/treatment_adherence_view.dart';
import '../../features/care_link/application/readmodels/caregiver_link_summary.dart';
import '../../features/treatment_management/presentation/navigation/treatment_navigation.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/presentation/widgets/caregiver_tab_bar.dart';

/// Care area of one confirmed profile: treatments and medications of the older adult.
class CaregiverCareRoute extends StatelessWidget {
  const CaregiverCareRoute({
    super.key,
    required this.profile,
    required this.treatments,
    required this.onOpenAdherence,
    required this.onSessionInvalidated,
    this.createTreatmentAdherenceBloc,
    this.createPersonAdherenceBloc,
  });

  final CaregiverLinkSummary profile;
  final TreatmentNavigation treatments;
  final LevelBloc Function(String olderAdultId)? createPersonAdherenceBloc;
  final LevelBloc Function(String olderAdultId, String treatmentId)?
  createTreatmentAdherenceBloc;

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
              personName: profile.fullName,
              personBadgeBuilder: createPersonAdherenceBloc == null
                  ? null
                  : (invalidated) => AdherenceBadgeView(
                      createBloc: () =>
                          createPersonAdherenceBloc!(profile.olderAdultId),
                      onSessionInvalidated: invalidated,
                    ),
              adherenceBuilder: createTreatmentAdherenceBloc == null
                  ? null
                  : (id, invalidated) => TreatmentAdherenceView(
                      key: ValueKey('treatment-adherence-$id'),
                      createBloc: () => createTreatmentAdherenceBloc!(
                        profile.olderAdultId,
                        id,
                      ),
                      onSessionInvalidated: invalidated,
                    ),
              navigationBuilder: (detailContext) => CaregiverTabBar(
                selected: CaregiverTab.person,
                enabledTabs: const {CaregiverTab.home, CaregiverTab.person},
                onSelected: (tab) {
                  final navigator = Navigator.of(detailContext);
                  if (tab == CaregiverTab.home) {
                    navigator.popUntil((route) => route.isFirst);
                  } else if (tab == CaregiverTab.person) {
                    final person = ModalRoute.of(context);
                    navigator.popUntil(
                      (route) => route == person || route.isFirst,
                    );
                  }
                },
              ),
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
