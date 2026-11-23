import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/presentation/theme/tata_typography.dart';
import '../bloc/recovery/recovery_bloc.dart';
import '../bloc/recovery/recovery_event.dart';
import '../bloc/recovery/recovery_state.dart';

/// Extension of the access flow, using Tata's existing native form vocabulary.
class PasswordRecoveryScreen extends StatefulWidget {
  const PasswordRecoveryScreen({super.key});
  @override
  State<PasswordRecoveryScreen> createState() => _PasswordRecoveryScreenState();
}

class _PasswordRecoveryScreenState extends State<PasswordRecoveryScreen> {
  final _email = TextEditingController();
  final _code = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    return BlocConsumer<RecoveryBloc, RecoveryState>(
      listener: (context, state) {
        if (state.status == RecoveryStatus.codeRequested &&
            state.errorCode == null) {
          _code.clear();
        }
        if (state.status == RecoveryStatus.completed) {
          _password.clear();
          _code.clear();
        }
      },
      builder: (context, state) {
        final error = switch (state.errorCode) {
          null => null,
          'INVALID_EMAIL' => text.invalidEmail,
          'INVALID_PASSWORD' => text.registrationPasswordError,
          'INVALID_RECOVERY_CODE' => text.invalidRecoveryCode,
          'NETWORK_UNAVAILABLE' => text.networkUnavailable,
          'RATE_LIMITED' => text.rateLimited,
          _ => text.genericRecoveryError,
        };
        return PopScope(
          canPop: !state.busy,
          child: Scaffold(
            body: SafeArea(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(22, 28, 22, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(text.recoveryTitle, style: TataTypography.heading),
                        const SizedBox(height: 12),
                        if (state.status == RecoveryStatus.completed)
                          Text(
                            text.recoverySuccess,
                            style: TataTypography.subtitle,
                          )
                        else ...[
                          Text(
                            state.email == null
                                ? text.recoveryExplanation
                                : text.recoveryAccepted,
                            style: TataTypography.subtitle,
                          ),
                          const SizedBox(height: 28),
                          Text(text.emailLabel, style: TataTypography.label),
                          const SizedBox(height: 8),
                          TextField(
                            key: const Key('recovery-email'),
                            controller: _email,
                            enabled: !state.busy && state.email == null,
                            keyboardType: TextInputType.emailAddress,
                            autocorrect: false,
                            autofillHints: const [AutofillHints.email],
                            decoration: InputDecoration(
                              hintText: text.emailHint,
                            ),
                          ),
                          if (state.email != null) ...[
                            const SizedBox(height: 20),
                            Text(
                              text.verificationCode,
                              style: TataTypography.label,
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              key: const Key('recovery-code'),
                              controller: _code,
                              enabled: !state.busy,
                              keyboardType: TextInputType.number,
                              autofillHints: const [AutofillHints.oneTimeCode],
                              maxLength: 6,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              decoration: const InputDecoration(
                                counterText: '',
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(text.newPassword, style: TataTypography.label),
                            const SizedBox(height: 8),
                            TextField(
                              key: const Key('recovery-password'),
                              controller: _password,
                              enabled: !state.busy,
                              obscureText: true,
                              autocorrect: false,
                              enableSuggestions: false,
                              autofillHints: const [AutofillHints.newPassword],
                              decoration: InputDecoration(
                                hintText: text.registrationPasswordHint,
                              ),
                            ),
                          ],
                          if (error != null) ...[
                            const SizedBox(height: 16),
                            Semantics(
                              liveRegion: true,
                              child: Text(
                                error,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: state.busy
                                ? null
                                : () {
                                    FocusScope.of(context).unfocus();
                                    context.read<RecoveryBloc>().add(
                                      state.email == null
                                          ? RecoveryRequested(_email.text)
                                          : RecoveryCompleted(
                                              _code.text,
                                              _password.text,
                                            ),
                                    );
                                  },
                            child: Text(
                              state.busy
                                  ? text.processing
                                  : state.email == null
                                  ? text.sendRecoveryCode
                                  : text.changePassword,
                            ),
                          ),
                          if (state.email != null)
                            TextButton(
                              onPressed: state.busy
                                  ? null
                                  : () => context.read<RecoveryBloc>().add(
                                      RecoveryRequested(state.email!),
                                    ),
                              child: Text(text.resendCode),
                            ),
                        ],
                        const SizedBox(height: 20),
                        TextButton(
                          onPressed: state.busy
                              ? null
                              : () => Navigator.of(context).pop(),
                          child: Text(text.backToSignIn),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
