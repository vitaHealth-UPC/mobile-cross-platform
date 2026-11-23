import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/application/session/session_owner.dart';
import '../../application/readmodels/remembered_adult.dart';
import '../bloc/access/access_bloc.dart';
import '../bloc/access/access_event.dart';
import '../bloc/access/access_state.dart';
import '../bloc/pin/pin_bloc.dart';
import '../bloc/plan_choice/plan_choice_cubit.dart';
import '../bloc/recovery/recovery_bloc.dart';
import '../bloc/registration/registration_bloc.dart';
import '../screens/landing_value_screen.dart';
import '../screens/login_screen.dart';
import '../screens/onboarding_screen.dart';
import '../screens/password_recovery_screen.dart';
import 'pin_route.dart';
import 'plan_choice_route.dart';
import 'registration_route.dart';

/// Adapts public session state to widgets without exposing credentials to the UI.
class AccessRoute extends StatefulWidget {
  const AccessRoute({
    super.key,
    this.createRegistrationBloc,
    this.createRecoveryBloc,
    this.authenticatedBuilder,
    this.consentBuilder,
    this.invitationBuilder,
    this.adultBuilder,
    this.loadRememberedAdult,
    this.createPinAccessBloc,
    this.createPlanChoiceCubit,
    this.contactUri,
    this.openContact,
    this.applyChosenPlan,
  });
  final RegistrationBloc Function()? createRegistrationBloc;
  final RecoveryBloc Function()? createRecoveryBloc;
  final Widget Function(BuildContext, VoidCallback, VoidCallback)?
  authenticatedBuilder;
  final Widget Function(BuildContext, VoidCallback, VoidCallback)?
  consentBuilder;
  final WidgetBuilder? invitationBuilder;
  final Widget Function(BuildContext, VoidCallback, VoidCallback)? adultBuilder;

  /// Reads the adult remembered after PIN enrollment on this device, if any.
  final Future<RememberedAdult?> Function()? loadRememberedAdult;

  /// Creates PIN access state for the remembered adult identifier.
  final PinBloc Function(String olderAdultId)? createPinAccessBloc;

  /// Plans shown before registration; without it Start opens registration.
  final PlanChoiceCubit Function()? createPlanChoiceCubit;
  final Uri? contactUri;
  final Future<bool> Function(Uri uri)? openContact;

  /// Activates the chosen plan once the new account is verified.
  final Future<bool> Function(String planCode)? applyChosenPlan;

  @override
  State<AccessRoute> createState() => _AccessRouteState();
}

/// Keeps onboarding navigation local while the bloc remains the session authority.
class _AccessRouteState extends State<AccessRoute> {
  bool _showOnboarding = true;
  RememberedAdult? _remembered;

  @override
  void initState() {
    super.initState();
    _loadRemembered();
  }

  /// A storage failure only hides the shortcut; email access stays available.
  Future<void> _loadRemembered() async {
    final load = widget.loadRememberedAdult;
    if (load == null) return;
    RememberedAdult? adult;
    try {
      adult = await load();
    } on Exception {
      adult = null;
    }
    if (!mounted) return;
    setState(() {
      _remembered = adult;
      if (adult != null) _showOnboarding = false;
    });
  }

  Future<void> _pinAccess(BuildContext context, RememberedAdult adult) async {
    final factory = widget.createPinAccessBloc!;
    final signedIn = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (routeContext) => PinRoute(
          createBloc: () => factory(adult.id),
          adultName: adult.name,
          onCompleted: () => Navigator.of(routeContext).pop(true),
          onBack: () => Navigator.of(routeContext).pop(false),
        ),
      ),
    );
    if (signedIn == true && context.mounted) {
      context.read<AccessBloc>().add(const AccessRestoreRequested());
    }
  }

  /// Start: compare plans first when they are available (US-48, US-49).
  Future<void> _start(BuildContext context) async {
    final plans = widget.createPlanChoiceCubit;
    if (plans == null) return _register(context);
    final continueToPlans = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (landingContext) => LandingValueScreen(
          onStart: () => Navigator.of(landingContext).pop(true),
        ),
      ),
    );
    if (continueToPlans != true || !context.mounted) return;
    final choice = await Navigator.of(context).push<PlanChoice>(
      MaterialPageRoute(
        builder: (_) => PlanChoiceRoute(
          createCubit: plans,
          contactUri: widget.contactUri,
          openContact: widget.openContact,
        ),
      ),
    );
    if (choice == null || !context.mounted) return;
    await _register(context, planCode: choice.plan?.code);
  }

  Future<void> _register(BuildContext context, {String? planCode}) async {
    setState(() => _showOnboarding = false);
    final factory = widget.createRegistrationBloc;
    if (factory == null) return;
    final verified = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (_) => factory(),
          child: const RegistrationRoute(),
        ),
      ),
    );
    if (verified != true || !context.mounted) return;
    final apply = widget.applyChosenPlan;
    if (planCode != null && apply != null) {
      final messenger = ScaffoldMessenger.of(context);
      final failed = AppLocalizations.of(context).planChoiceApplyFailed;
      if (!await apply(planCode)) {
        messenger.showSnackBar(SnackBar(content: Text(failed)));
      }
      if (!context.mounted) return;
    }
    context.read<AccessBloc>().add(const AccessRestoreRequested());
  }

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    return BlocConsumer<AccessBloc, AccessState>(
      // Sign-out or consent withdrawal may change which adult this device remembers.
      listenWhen: (previous, current) =>
          previous.status != current.status &&
          current.status == AccessStatus.anonymous,
      listener: (_, _) => _loadRemembered(),
      builder: (context, state) {
        if (state.status == AccessStatus.initial) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (state.status == AccessStatus.authenticated) {
          final builder = state.session!.owner.role == SessionRole.caregiver
              ? widget.authenticatedBuilder
              : widget.adultBuilder;
          if (builder != null) {
            return builder(
              context,
              () => context.read<AccessBloc>().add(
                const AccessSignOutRequested(),
              ),
              () => context.read<AccessBloc>().add(
                const AccessRestoreRequested(),
              ),
            );
          }
          return Scaffold(
            body: SafeArea(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(text.sessionConfirmed),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => context.read<AccessBloc>().add(
                        const AccessSignOutRequested(),
                      ),
                      child: Text(text.signOut),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        void unavailable() => ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(text.accessMethodUnavailable)));

        if (state.status == AccessStatus.consentRequired) {
          final builder = widget.consentBuilder;
          if (builder != null) {
            return builder(
              context,
              () => context.read<AccessBloc>().add(
                const AccessSignOutRequested(),
              ),
              () => context.read<AccessBloc>().add(
                const AccessRestoreRequested(),
              ),
            );
          }
          return Scaffold(
            body: SafeArea(child: Center(child: Text(text.adultConsentTitle))),
          );
        }

        if (state.status == AccessStatus.anonymous && _showOnboarding) {
          return OnboardingScreen(
            onStart: () => _start(context),
            onSignIn: () => setState(() => _showOnboarding = false),
          );
        }

        return LoginScreen(
          onInvitation: widget.invitationBuilder == null
              ? null
              : () async {
                  await Navigator.of(context).push<bool>(
                    MaterialPageRoute(builder: widget.invitationBuilder!),
                  );
                  if (context.mounted) {
                    context.read<AccessBloc>().add(
                      const AccessRestoreRequested(),
                    );
                  }
                },
          busy: state.status == AccessStatus.busy,
          errorText: _error(text, state.errorCode),
          onSignIn: (email, password) => context.read<AccessBloc>().add(
            AccessSignInSubmitted(email, password),
          ),
          onRecover: widget.createRecoveryBloc == null
              ? unavailable
              : () {
                  Navigator.of(context).push<void>(
                    MaterialPageRoute(
                      builder: (_) => BlocProvider(
                        create: (_) => widget.createRecoveryBloc!(),
                        child: const PasswordRecoveryScreen(),
                      ),
                    ),
                  );
                },
          onRegister: widget.createRegistrationBloc == null
              ? unavailable
              : () => _register(context),
          onGoogle: unavailable,
          onFacebook: unavailable,
          onPinAccess: _remembered == null || widget.createPinAccessBloc == null
              ? null
              : () => _pinAccess(context, _remembered!),
        );
      },
    );
  }

  String? _error(AppLocalizations text, String? code) => switch (code) {
    null => null,
    'INVALID_EMAIL' => text.invalidEmail,
    'INVALID_PASSWORD' => text.invalidPassword,
    'INVALID_CREDENTIALS' ||
    'AUTHENTICATION_REQUIRED' => text.invalidCredentials,
    'NETWORK_UNAVAILABLE' => text.networkUnavailable,
    'ACCESS_DENIED' => text.accessDenied,
    'RATE_LIMITED' => text.rateLimited,
    _ => text.genericAccessError,
  };
}
