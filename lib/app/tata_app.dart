import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../features/accessibility_preferences/presentation/cubit/appearance_cubit.dart';
import '../features/accessibility_preferences/presentation/theme/appearance.dart';
import '../features/identity_subscription/application/readmodels/remembered_adult.dart';
import '../features/identity_subscription/presentation/bloc/access/access_bloc.dart';
import '../features/identity_subscription/presentation/bloc/access/access_event.dart';
import '../features/identity_subscription/presentation/bloc/access/access_state.dart';
import '../features/identity_subscription/presentation/bloc/pin/pin_bloc.dart';
import '../features/identity_subscription/presentation/bloc/recovery/recovery_bloc.dart';
import '../features/identity_subscription/presentation/bloc/registration/registration_bloc.dart';
import '../features/identity_subscription/presentation/navigation/access_route.dart';
import '../l10n/generated/app_localizations.dart';
import '../shared/application/session/session_owner.dart';
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
    this.loadRememberedAdult,
    this.createPinAccessBloc,
    this.createAppearanceCubit,
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
  final Future<RememberedAdult?> Function()? loadRememberedAdult;
  final PinBloc Function(String olderAdultId)? createPinAccessBloc;

  /// Optional app-wide appearance (accessibility and language of the signed-in owner).
  /// Without it the application keeps the default light Spanish experience.
  final AppearanceCubit Function()? createAppearanceCubit;

  Widget _app(AppearanceState? appearance) {
    final preferences = appearance?.accessibility;
    return MaterialApp(
      title: 'Tata',
      debugShowCheckedModeBanner: false,
      theme: preferences == null
          ? TataTheme.light
          : Appearance.themeFor(preferences),
      locale: appearance == null
          ? const Locale('es')
          : Appearance.localeFor(appearance.language),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: preferences == null
          ? null
          : (context, child) => Appearance.wrap(
              context,
              preferences,
              child ?? const SizedBox(),
            ),
      home: AccessRoute(
        createRegistrationBloc: createRegistrationBloc,
        createRecoveryBloc: createRecoveryBloc,
        authenticatedBuilder: authenticatedBuilder,
        consentBuilder: consentBuilder,
        invitationBuilder: invitationBuilder,
        adultBuilder: adultBuilder,
        loadRememberedAdult: loadRememberedAdult,
        createPinAccessBloc: createPinAccessBloc,
      ),
    );
  }

  /// Only full caregiver and older-adult sessions own preferences.
  static String? _preferencesOwner(AccessState state) {
    final owner = state.session?.owner;
    if (owner == null || owner.role == SessionRole.linkSetup) return null;
    return owner.id;
  }

  @override
  Widget build(BuildContext context) {
    final appearance = createAppearanceCubit;
    return BlocProvider(
      create: (_) => createAccessBloc()..add(const AccessRestoreRequested()),
      child: appearance == null
          ? _app(null)
          : BlocProvider(
              create: (_) => appearance(),
              child: Builder(
                builder: (context) => BlocListener<AccessBloc, AccessState>(
                  listenWhen: (previous, current) =>
                      _preferencesOwner(previous) != _preferencesOwner(current),
                  listener: (context, state) => context
                      .read<AppearanceCubit>()
                      .bindOwner(_preferencesOwner(state)),
                  child: BlocBuilder<AppearanceCubit, AppearanceState>(
                    builder: (context, state) => _app(state),
                  ),
                ),
              ),
            ),
    );
  }
}
