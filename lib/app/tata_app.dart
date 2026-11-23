import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../features/identity_subscription/presentation/bloc/access/access_bloc.dart';
import '../features/identity_subscription/presentation/bloc/access/access_event.dart';
import '../features/identity_subscription/presentation/bloc/recovery/recovery_bloc.dart';
import '../features/identity_subscription/presentation/bloc/registration/registration_bloc.dart';
import '../features/identity_subscription/presentation/navigation/access_route.dart';
import '../l10n/generated/app_localizations.dart';
import '../shared/presentation/theme/tata_theme.dart';

/// Composition root. Feature navigation and dependencies enter here as flows land.
class TataApp extends StatelessWidget {
  const TataApp({
    super.key,
    required this.createAccessBloc,
    this.createRegistrationBloc,
    this.createRecoveryBloc,
    this.authenticatedBuilder,
    this.consentBuilder,
    this.invitationBuilder,
    this.adultBuilder,
  });

  final AccessBloc Function() createAccessBloc;
  final RegistrationBloc Function()? createRegistrationBloc;
  final RecoveryBloc Function()? createRecoveryBloc;
  final Widget Function(BuildContext, VoidCallback, VoidCallback)?
  authenticatedBuilder;
  final Widget Function(BuildContext, VoidCallback, VoidCallback)?
  consentBuilder;
  final WidgetBuilder? invitationBuilder;
  final Widget Function(BuildContext, VoidCallback, VoidCallback)? adultBuilder;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tata',
      debugShowCheckedModeBanner: false,
      theme: TataTheme.light,
      locale: const Locale('es'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: BlocProvider(
        create: (_) => createAccessBloc()..add(const AccessRestoreRequested()),
        child: AccessRoute(
          createRegistrationBloc: createRegistrationBloc,
          createRecoveryBloc: createRecoveryBloc,
          authenticatedBuilder: authenticatedBuilder,
          consentBuilder: consentBuilder,
          invitationBuilder: invitationBuilder,
          adultBuilder: adultBuilder,
        ),
      ),
    );
  }
}
