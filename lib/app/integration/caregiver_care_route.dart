import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/accessibility_preferences/presentation/navigation/preferences_navigation.dart';
import '../../features/adherence_analytics/presentation/bloc/level/level_bloc.dart';
import '../../features/adherence_analytics/presentation/navigation/adherence_level_view.dart';
import '../../features/care_link/application/readmodels/caregiver_link_summary.dart';
import '../../features/care_link/presentation/bloc/profile_editor/profile_editor_cubit.dart';
import '../../features/care_link/presentation/navigation/profile_editor_route.dart';
import '../../features/family_monitoring/application/readmodels/family_summary.dart';
import '../../features/family_monitoring/presentation/navigation/family_monitoring_navigation.dart';
import '../../features/identity_subscription/presentation/bloc/subscription/subscription_bloc.dart';
import '../../features/identity_subscription/presentation/bloc/subscription/subscription_event.dart';
import '../../features/identity_subscription/presentation/screens/plan_subscription_screen.dart';
import '../../features/inventory_replenishment/presentation/navigation/inventory_navigation.dart';
import '../../features/omission_escalation/application/services/omission_push_facade.dart';
import '../../features/omission_escalation/presentation/widgets/follow_omission_push.dart';
import '../../features/treatment_management/domain/entities/medication.dart';
import '../../features/treatment_management/presentation/navigation/treatment_navigation.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/presentation/widgets/caregiver_tab_bar.dart';
import 'caregiver_treatment_entry.dart';

/// Care area of one confirmed profile: the family follow-up (summary, alerts, notes) with
/// treatments, medications and settings under "More".
class CaregiverCareRoute extends StatelessWidget {
  const CaregiverCareRoute({
    super.key,
    required this.profile,
    required this.caregiverId,
    required this.treatments,
    required this.monitoring,
    required this.push,
    required this.onOpenAdherence,
    required this.onOpenSettings,
    required this.onSessionInvalidated,
    this.createTreatmentAdherenceBloc,
    this.createPersonAdherenceBloc,
    this.inventory,
    this.createProfileEditorCubit,
  });

  final CaregiverLinkSummary profile;
  final String caregiverId;
  final TreatmentNavigation treatments;
  final FamilyMonitoringNavigation monitoring;
  final OmissionPushFacade push;

  /// Stock of each medication (US-40 to US-43); absent when not wired.
  final InventoryNavigation? inventory;
  final ProfileEditorCubit Function(String olderAdultId)?
  createProfileEditorCubit;
  final LevelBloc Function(String olderAdultId)? createPersonAdherenceBloc;
  final LevelBloc Function(String olderAdultId, String treatmentId)?
  createTreatmentAdherenceBloc;

  /// Opens the adherence history of this person; owned by the host.
  final void Function(BuildContext context) onOpenAdherence;

  /// Opens the caregiver's own settings; owned by the host.
  final void Function(BuildContext context) onOpenSettings;
  final VoidCallback onSessionInvalidated;

  @override
  Widget build(BuildContext context) => FollowOmissionPush(
    followKey: profile.olderAdultId,
    follow: () => push.followCaregiver(caregiverId, profile.olderAdultId),
    child: Builder(
      builder: (inner) => monitoring.caregiverHome(
        olderAdultId: profile.olderAdultId,
        olderAdultName: profile.fullName,
        onHistory: () => onOpenAdherence(inner),
        onAddMedication: () => treatments.openMedications(
          inner,
          profile.olderAdultId,
          onSessionInvalidated,
          personName: profile.fullName,
          onOpenInventory: _inventoryOpener(inner),
        ),
        onPerson: () => Navigator.of(inner).maybePop(),
        person: LinkedPersonSlots(
          linkedSince: profile.confirmedAt,
          onEdit: switch (createProfileEditorCubit) {
            final create? => (context) async => (await openProfileEditor(
              context,
              createCubit: () => create(profile.olderAdultId),
              onSessionInvalidated: onSessionInvalidated,
            ))?.fullName,
            null => null,
          },
          adherence: switch (createPersonAdherenceBloc) {
            final create? => (_) => AdherenceLevelView(
              createBloc: () => create(profile.olderAdultId),
              onSessionInvalidated: onSessionInvalidated,
            ),
            null => null,
          },
          treatment: (_) => treatments.activeMedicationsCard(
            profile.olderAdultId,
            onSessionInvalidated,
          ),
        ),
        onMore: () => _openMore(inner),
        onSessionInvalidated: onSessionInvalidated,
        onOpenStock: inventory == null
            ? null
            : (StockAttention stock) => _openInventory(
                inner,
                inner,
                stock.medicationId,
                stock.medicationName,
              ),
      ),
    ),
  );

  /// Opens the stock of a medication with the person bar, as Figma 563:1632 draws it.
  void Function(BuildContext, Medication)? _inventoryOpener(
    BuildContext personContext,
  ) {
    if (inventory == null) return null;
    return (context, medication) =>
        _openInventory(context, personContext, medication.id, medication.label);
  }

  Future<void> _openInventory(
    BuildContext context,
    BuildContext personContext,
    String medicationId,
    String medicationLabel,
  ) => inventory!.open(
    context,
    medicationId: medicationId,
    medicationLabel: medicationLabel,
    personName: profile.fullName,
    onSessionInvalidated: onSessionInvalidated,
    navigationBuilder: (inventoryContext) => CaregiverTabBar(
      selected: CaregiverTab.person,
      enabledTabs: const {CaregiverTab.home, CaregiverTab.person},
      onSelected: (tab) {
        final navigator = Navigator.of(inventoryContext);
        if (tab == CaregiverTab.home) {
          navigator.popUntil((route) => route.isFirst);
        } else {
          final person = ModalRoute.of(personContext);
          navigator.popUntil((route) => route == person || route.isFirst);
        }
      },
    ),
  );

  /// Completes when the chosen flow closes, so the summary can be read again.
  Future<void> _openMore(BuildContext context) async {
    final text = AppLocalizations.of(context);
    final choice = await showModalBottomSheet<_MoreChoice>(
      context: context,
      showDragHandle: true,
      builder: (sheet) {
        Widget option(_MoreChoice choice, IconData icon, String title) =>
            ListTile(
              leading: Icon(icon),
              title: Text(title),
              onTap: () => Navigator.of(sheet).pop(choice),
            );
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              option(
                _MoreChoice.adherence,
                Icons.insights_outlined,
                text.adherenceHistoryTitle,
              ),
              option(
                _MoreChoice.treatments,
                Icons.assignment_outlined,
                text.tmTreatmentsTitle,
              ),
              option(
                _MoreChoice.medications,
                Icons.medication_outlined,
                text.tmMedicationsTitle,
              ),
              option(
                _MoreChoice.settings,
                Icons.settings_outlined,
                text.pfSettings,
              ),
            ],
          ),
        );
      },
    );
    if (choice == null || !context.mounted) return;
    switch (choice) {
      case _MoreChoice.adherence:
        onOpenAdherence(context);
      case _MoreChoice.treatments:
        await _openTreatments(context);
      case _MoreChoice.medications:
        await treatments.openMedications(
          context,
          profile.olderAdultId,
          onSessionInvalidated,
          personName: profile.fullName,
          onOpenInventory: _inventoryOpener(context),
        );
      case _MoreChoice.settings:
        onOpenSettings(context);
    }
  }

  Future<void> _openTreatments(BuildContext context) {
    return openCaregiverTreatments(
      context,
      olderAdultId: profile.olderAdultId,
      personName: profile.fullName,
      treatments: treatments,
      onSessionInvalidated: onSessionInvalidated,
      createPersonAdherenceBloc: createPersonAdherenceBloc,
      createTreatmentAdherenceBloc: createTreatmentAdherenceBloc,
    );
  }
}

/// Options of the caregiver's More sheet.
enum _MoreChoice { adherence, treatments, medications, settings }

/// The caregiver's own settings: notification delivery and accessibility.
class CaregiverSettingsRoute extends StatelessWidget {
  const CaregiverSettingsRoute({
    super.key,
    required this.caregiverId,
    required this.preferences,
    required this.onSessionInvalidated,
    this.createSubscriptionBloc,
  });

  final String caregiverId;
  final PreferencesNavigation preferences;
  final VoidCallback onSessionInvalidated;

  /// Plan and subscription of the caregiver's account; absent when not wired.
  final SubscriptionBloc Function()? createSubscriptionBloc;

  void _openSubscription(
    BuildContext context,
    SubscriptionBloc Function() create,
  ) => Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (_) => BlocProvider(
        create: (_) => create()..add(const SubscriptionRequested()),
        child: Builder(
          builder: (inner) => PlanSubscriptionScreen(
            clock: DateTime.now,
            onSessionInvalidated: () {
              Navigator.of(inner).popUntil((route) => route.isFirst);
              onSessionInvalidated();
            },
          ),
        ),
      ),
    ),
  );

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
              navigationBuilder: (notificationsContext) => CaregiverTabBar(
                selected: CaregiverTab.more,
                enabledTabs: const {CaregiverTab.home, CaregiverTab.more},
                onSelected: (tab) {
                  final navigator = Navigator.of(notificationsContext);
                  if (tab == CaregiverTab.home) {
                    navigator.popUntil((route) => route.isFirst);
                  } else if (tab == CaregiverTab.more) {
                    navigator.pop();
                  }
                },
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.accessibility_new),
            title: Text(text.pfAccessibilityTitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => preferences.openAccessibility(context, caregiverId),
          ),
          if (createSubscriptionBloc case final create?)
            ListTile(
              leading: const Icon(Icons.workspace_premium_outlined),
              title: Text(text.subTitle),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _openSubscription(context, create),
            ),
        ],
      ),
    );
  }
}
