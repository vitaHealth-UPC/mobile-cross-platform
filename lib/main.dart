import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'app/di/app_dependencies.dart';
import 'app/integration/adult_entry_route.dart';
import 'app/integration/caregiver_adherence_entry.dart';
import 'app/integration/caregiver_care_route.dart';
import 'app/tata_app.dart';
import 'features/accessibility_preferences/presentation/navigation/preferences_navigation.dart';
import 'features/care_link/presentation/navigation/caregiver_setup_route.dart';
import 'features/care_link/presentation/navigation/consent_route.dart';
import 'features/identity_subscription/presentation/bloc/access/access_bloc.dart';
import 'features/treatment_management/presentation/navigation/treatment_navigation.dart';

/// Initializes Flutter platform bindings and composes production dependencies.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final dependencies = AppDependencies.production();
  final treatments = TreatmentNavigation(dependencies.treatmentFactories);
  final preferences = PreferencesNavigation(dependencies.preferencesFactories);
  runApp(
    TataApp(
      createAccessBloc: dependencies.createAccessBloc,
      createRegistrationBloc: dependencies.createRegistrationBloc,
      createRecoveryBloc: dependencies.createRecoveryBloc,
      loadRememberedAdult: dependencies.readRememberedAdult,
      createPinAccessBloc: dependencies.createPinAccessBloc,
      createAppearanceCubit: dependencies.createAppearanceCubit,
      authenticatedBuilder: (context, signOut, invalidated) =>
          CaregiverSetupRoute(
            createBloc: dependencies.createProfilesBloc,
            onSignOut: signOut,
            onSessionInvalidated: invalidated,
            onOpenProfile: (link) => Navigator.of(context).push<void>(
              MaterialPageRoute(
                builder: (_) => CaregiverCareRoute(
                  profile: link,
                  treatments: treatments,
                  createPersonAdherenceBloc:
                      dependencies.createAdherenceWeekBloc,
                  createTreatmentAdherenceBloc:
                      dependencies.createTreatmentAdherenceBloc,
                  onOpenAdherence: (careContext) => openAdherenceFlow(
                    careContext,
                    link: link,
                    createHistoryBloc: dependencies.createAdherenceHistoryBloc,
                    createRecommendationsBloc:
                        dependencies.createAdherenceRecommendationsBloc,
                    onSessionInvalidated: invalidated,
                  ),
                  onSessionInvalidated: invalidated,
                ),
              ),
            ),
            onOpenSettings: (settingsContext) {
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
                    onSessionInvalidated: invalidated,
                  ),
                ),
              );
            },
          ),
      consentBuilder: (_, signOut, changed) => ConsentRoute(
        createBloc: dependencies.createConsentBloc,
        onSessionChanged: changed,
        onSignOut: signOut,
      ),
      adultBuilder: (context, signOut, changed) {
        final adultId = context.read<AccessBloc>().state.session?.owner.id;
        if (adultId == null) return const SizedBox.shrink();
        return AdultEntryRoute(
          key: ValueKey(adultId),
          olderAdultId: adultId,
          readRemembered: dependencies.readRememberedAdult,
          remember: dependencies.rememberAdult,
          forget: dependencies.forgetRememberedAdult,
          readAdultName: dependencies.readAdultName,
          createPinSetupBloc: dependencies.createPinSetupBloc,
          createHomeBloc: dependencies.createHomeBloc,
          createAgendaBloc: dependencies.createAgendaBloc,
          createDoseBloc: dependencies.createDoseBloc,
          createConsentBloc: dependencies.createConsentBloc,
          intakeSync: dependencies.intakeSync,
          onSignOut: signOut,
          onSessionChanged: changed,
          treatments: treatments,
          preferences: preferences,
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
