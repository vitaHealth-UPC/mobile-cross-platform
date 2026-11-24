import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'app/di/app_dependencies.dart';
import 'app/integration/adult_entry_route.dart';
import 'app/integration/caregiver_adherence_entry.dart';
import 'app/integration/caregiver_care_route.dart';
import 'app/integration/caregiver_treatment_entry.dart';
import 'app/integration/omission_background_handler.dart';
import 'app/integration/omission_destination_router.dart';
import 'app/integration/omission_messaging_host.dart';
import 'app/tata_app.dart';
import 'features/accessibility_preferences/presentation/navigation/preferences_navigation.dart';
import 'features/care_link/application/readmodels/caregiver_link_summary.dart';
import 'features/care_link/presentation/navigation/caregiver_setup_route.dart';
import 'features/care_link/presentation/navigation/consent_route.dart';
import 'features/family_monitoring/presentation/navigation/family_monitoring_navigation.dart';
import 'features/identity_subscription/presentation/bloc/access/access_bloc.dart';
import 'features/identity_subscription/presentation/bloc/access/access_event.dart';
import 'features/identity_subscription/presentation/bloc/access/access_state.dart';
import 'features/inventory_replenishment/presentation/navigation/inventory_navigation.dart';
import 'features/omission_escalation/application/readmodels/push_destination.dart';
import 'features/treatment_management/presentation/navigation/treatment_navigation.dart';
import 'l10n/generated/app_localizations.dart';
import 'shared/presentation/widgets/caregiver_tab_bar.dart';

/// Initializes Flutter platform bindings and composes production dependencies.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  registerOmissionBackgroundHandler();
  final backendPreparing = ValueNotifier(false);
  final dependencies = AppDependencies.production(
    onBackendPreparing: (value) => scheduleMicrotask(() {
      backendPreparing.value = value;
    }),
  );
  unawaited(dependencies.prepareBackend());
  final treatments = TreatmentNavigation(dependencies.treatmentFactories);
  final preferences = PreferencesNavigation(dependencies.preferencesFactories);
  final inventory = InventoryNavigation(dependencies.createInventoryBloc);
  final monitoring = FamilyMonitoringNavigation(
    dependencies.familyMonitoringFactories,
  );
  final push = dependencies.omissionPush(
    installationId: await dependencies.readPushInstallationId(),
    registrationEnabled: omissionPushEnabled,
  );

  final delivery = dependencies.createOmissionDelivery(push);
  final navigatorKey = GlobalKey<NavigatorState>();
  final requestedDose = ValueNotifier<OlderAdultDoseDestination?>(null);

  void invalidateAccess() {
    navigatorKey.currentContext?.read<AccessBloc>().add(
      const AccessRestoreRequested(),
    );
  }

  void openSettings(
    BuildContext settingsContext,
    VoidCallback onSessionInvalidated,
  ) {
    final caregiverId = settingsContext
        .read<AccessBloc>()
        .state
        .session
        ?.owner
        .id;
    if (caregiverId == null) return;
    Navigator.of(settingsContext).push<void>(
      MaterialPageRoute(
        builder: (_) => CaregiverSettingsRoute(
          caregiverId: caregiverId,
          preferences: preferences,
          onSessionInvalidated: onSessionInvalidated,
          createSubscriptionBloc: dependencies.createSubscriptionBloc,
        ),
      ),
    );
  }

  Future<void> openProfile(
    BuildContext context,
    CaregiverLinkSummary link,
    VoidCallback invalidated, {
    CaregiverTab initialTab = CaregiverTab.home,
    String? initialIntakeId,
  }) async {
    final caregiverId = context.read<AccessBloc>().state.session?.owner.id;
    if (caregiverId == null) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => CaregiverCareRoute(
          profile: link,
          initialTab: initialTab,
          initialIntakeId: initialIntakeId,
          caregiverId: caregiverId,
          treatments: treatments,
          monitoring: monitoring,
          push: push,
          inventory: inventory,
          createProfileEditorCubit: dependencies.createProfileEditorCubit,
          createPersonAdherenceBloc: dependencies.createAdherenceWeekBloc,
          createTreatmentAdherenceBloc:
              dependencies.createTreatmentAdherenceBloc,
          onOpenAdherence: (careContext) => openAdherenceFlow(
            careContext,
            link: link,
            createHistoryBloc: dependencies.createAdherenceHistoryBloc,
            createRecommendationsBloc:
                dependencies.createAdherenceRecommendationsBloc,
            onSessionInvalidated: invalidated,
            onApplyAdjustments: () => openCaregiverTreatments(
              careContext,
              olderAdultId: link.olderAdultId,
              personName: link.fullName,
              treatments: treatments,
              onSessionInvalidated: invalidated,
              createPersonAdherenceBloc: dependencies.createAdherenceWeekBloc,
              createTreatmentAdherenceBloc:
                  dependencies.createTreatmentAdherenceBloc,
            ),
          ),
          onOpenSettings: (careContext) =>
              openSettings(careContext, invalidated),
          onSessionInvalidated: invalidated,
        ),
      ),
    );
  }

  final notificationRouter = OmissionDestinationRouter(
    mayOpen: (destination) async {
      final access = navigatorKey.currentContext?.read<AccessBloc>();
      return access?.state.status == AccessStatus.authenticated &&
          await push.canOpen(destination);
    },
    sessionGeneration: () => dependencies.sessionGeneration,
    readProfiles: dependencies.readConfirmedCareProfiles,
    openCaregiver: (profile, intakeId) async {
      final context = navigatorKey.currentContext;
      final navigator = navigatorKey.currentState;
      if (context == null || navigator == null) return;
      navigator.popUntil((route) => route.isFirst);
      await openProfile(
        context,
        profile,
        invalidateAccess,
        initialTab: CaregiverTab.alerts,
        initialIntakeId: intakeId,
      );
    },
    openAdultDose: (destination) {
      navigatorKey.currentState?.popUntil((route) => route.isFirst);
      requestedDose.value = destination;
    },
    openAdultHome: () =>
        navigatorKey.currentState?.popUntil((route) => route.isFirst),
    onUnavailable: (code) {
      final context = navigatorKey.currentContext;
      if (context == null) return;
      final text = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            code == 'NETWORK_UNAVAILABLE'
                ? text.networkUnavailable
                : text.homeErrorBody,
          ),
        ),
      );
      if (code == 'ACCESS_DENIED' || code == 'AUTHENTICATION_REQUIRED') {
        invalidateAccess();
      }
    },
  );

  runApp(
    TataApp(
      navigatorKey: navigatorKey,
      backendPreparing: backendPreparing,
      applicationObserver: (child) => OmissionMessagingHost(
        delivery: delivery,
        onOpen: notificationRouter.open,
        onAccessUnavailable: () => requestedDose.value = null,
        onDisposed: () {
          notificationRouter.dispose();
          requestedDose.dispose();
        },
        child: child,
      ),
      createAccessBloc: () =>
          dependencies.createAccessBloc(beforeSignOut: delivery.beforeSignOut),
      createRegistrationBloc: dependencies.createRegistrationBloc,
      createRecoveryBloc: dependencies.createRecoveryBloc,
      loadRememberedAdult: dependencies.readRememberedAdult,
      createPinAccessBloc: dependencies.createPinAccessBloc,
      createAppearanceCubit: dependencies.createAppearanceCubit,
      createPlanChoiceCubit: dependencies.createPlanChoiceCubit,
      contactUri: dependencies.contactUri,
      openContact: dependencies.openContact,
      applyChosenPlan: dependencies.applyChosenPlan,
      authenticatedBuilder: (context, signOut, invalidated) =>
          CaregiverSetupRoute(
            createBloc: dependencies.createProfilesBloc,
            onSignOut: signOut,
            onSessionInvalidated: invalidated,
            onOpenProfile: (link) => openProfile(context, link, invalidated),
            onOpenSettings: (settingsContext) =>
                openSettings(settingsContext, invalidated),
          ),
      consentBuilder: (_, signOut, changed) => ConsentRoute(
        createBloc: dependencies.createConsentBloc,
        onSessionChanged: changed,
        onSignOut: signOut,
      ),
      adultBuilder: (context, signOut, changed) {
        final adultId = context.read<AccessBloc>().state.session?.owner.id;
        if (adultId == null) return const SizedBox.shrink();
        return ValueListenableBuilder<OlderAdultDoseDestination?>(
          valueListenable: requestedDose,
          builder: (_, request, _) => AdultEntryRoute(
            key: ValueKey(adultId),
            olderAdultId: adultId,
            initialIntakeId: request?.olderAdultId == adultId
                ? request?.intakeId
                : null,
            onInitialIntakeConsumed: () {
              if (requestedDose.value == request) requestedDose.value = null;
            },
            readRemembered: dependencies.readRememberedAdult,
            remember: dependencies.rememberAdult,
            forget: dependencies.forgetRememberedAdult,
            readAdultName: dependencies.readAdultName,
            createPinSetupBloc: dependencies.createPinSetupBloc,
            createHomeBloc: dependencies.createHomeBloc,
            createAgendaBloc: dependencies.createAgendaBloc,
            createDoseBloc: dependencies.createDoseBloc,
            createVoiceBloc: dependencies.createVoiceBloc,
            createPhraseSpeaker: dependencies.createPhraseSpeaker,
            createConsentBloc: dependencies.createConsentBloc,
            intakeSync: dependencies.intakeSync,
            onSignOut: signOut,
            onSessionChanged: changed,
            treatments: treatments,
            preferences: preferences,
            monitoring: monitoring,
            push: push,
            reminders: dependencies.intakeReminders,
          ),
        );
      },
      invitationBuilder: (context) => ConsentRoute(
        createBloc: dependencies.createConsentBloc,
        invitationEntry: true,
        onSessionChanged: () => Navigator.of(context).pop(false),
        onSignOut: () => Navigator.of(context).pop(false),
      ),
    ),
  );
}
