import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/application/session/session_owner.dart';
import '../bloc/access/access_bloc.dart';
import '../bloc/access/access_event.dart';
import '../bloc/access/access_state.dart';
import '../bloc/recovery/recovery_bloc.dart';
import '../bloc/registration/registration_bloc.dart';
import '../screens/login_screen.dart';
import '../screens/onboarding_screen.dart';
import '../screens/password_recovery_screen.dart';
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
  });
  final RegistrationBloc Function()? createRegistrationBloc;
  final RecoveryBloc Function()? createRecoveryBloc;
  final Widget Function(BuildContext, VoidCallback, VoidCallback)?
  authenticatedBuilder;
  final Widget Function(BuildContext, VoidCallback, VoidCallback)?
  consentBuilder;
  final WidgetBuilder? invitationBuilder;
  final Widget Function(BuildContext, VoidCallback, VoidCallback)? adultBuilder;

  @override
  State<AccessRoute> createState() => _AccessRouteState();
}

/// Keeps onboarding navigation local while the bloc remains the session authority.
class _AccessRouteState extends State<AccessRoute> {
  bool _showOnboarding = true;

  Future<void> _register(BuildContext context) async {
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
    if (verified == true && context.mounted) {
      context.read<AccessBloc>().add(const AccessRestoreRequested());
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    return BlocBuilder<AccessBloc, AccessState>(
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
            onStart: () => _register(context),
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
