import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../bloc/registration/registration_bloc.dart';
import '../bloc/registration/registration_event.dart';
import '../bloc/registration/registration_state.dart';
import '../screens/caregiver_registration_screen.dart';

/// Connects registration state to its screen and returns after verified access.
class RegistrationRoute extends StatelessWidget {
  const RegistrationRoute({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocConsumer<RegistrationBloc, RegistrationState>(
        listener: (context, state) {
          if (state.status == RegistrationStatus.verified) {
            Navigator.of(context).pop(true);
          }
        },
        builder: (context, state) {
          final text = AppLocalizations.of(context);
          final bloc = context.read<RegistrationBloc>();
          final error = switch (state.errorCode) {
            null => null,
            'INVALID_NAME' => text.invalidName,
            'INVALID_EMAIL' => text.invalidEmail,
            'INVALID_PASSWORD' => text.registrationPasswordError,
            'DUPLICATE_EMAIL' => text.duplicateEmail,
            'INVALID_VERIFICATION' => text.invalidVerification,
            'VERIFICATION_EXPIRED' => text.verificationExpired,
            'NETWORK_UNAVAILABLE' => text.networkUnavailable,
            'RATE_LIMITED' => text.rateLimited,
            _ => text.genericAccessError,
          };
          return CaregiverRegistrationScreen(
            busy: state.busy,
            hasAccount: state.hasAccount,
            errorText: error,
            resent: state.resent,
            onRegister: (name, email, password) =>
                bloc.add(RegistrationSubmitted(name, email, password)),
            onVerify: (code) => bloc.add(VerificationSubmitted(code)),
            onResend: () => bloc.add(const VerificationRequested()),
          );
        },
      );
}
