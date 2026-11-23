import 'package:flutter/widgets.dart';

import 'app/di/app_dependencies.dart';
import 'app/tata_app.dart';
import 'features/care_link/presentation/navigation/caregiver_setup_route.dart';
import 'features/care_link/presentation/navigation/consent_management_route.dart';
import 'features/care_link/presentation/navigation/consent_route.dart';

/// Initializes Flutter platform bindings and composes production dependencies.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final dependencies = AppDependencies.production();
  runApp(
    TataApp(
      createAccessBloc: dependencies.createAccessBloc,
      createRegistrationBloc: dependencies.createRegistrationBloc,
      createRecoveryBloc: dependencies.createRecoveryBloc,
      authenticatedBuilder: (_, signOut, invalidated) => CaregiverSetupRoute(
        createBloc: dependencies.createProfilesBloc,
        onSignOut: signOut,
        onSessionInvalidated: invalidated,
      ),
      consentBuilder: (_, signOut, changed) => ConsentRoute(
        createBloc: dependencies.createConsentBloc,
        onSessionChanged: changed,
        onSignOut: signOut,
      ),
      adultBuilder: (_, signOut, changed) => ConsentManagementRoute(
        createBloc: dependencies.createConsentBloc,
        onSessionChanged: changed,
        onSignOut: signOut,
      ),
      invitationBuilder: (context) => ConsentRoute(
        createBloc: dependencies.createConsentBloc,
        invitationEntry: true,
        onSessionChanged: () => Navigator.of(context).pop(false),
        onSignOut: () => Navigator.of(context).pop(false),
      ),
    ),
  );
}
