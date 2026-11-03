import 'package:flutter/material.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/presentation/theme/tata_colors.dart';
import '../../../../shared/presentation/theme/tata_typography.dart';
import '../widgets/access_form.dart';
import '../widgets/social_access_button.dart';

/// Figma 641:16 expressed with Flutter layout and native fields, never a screen image.
class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.onSignIn,
    required this.onRecover,
    required this.onRegister,
    required this.onGoogle,
    required this.onFacebook,
    this.busy = false,
    this.errorText,
    this.onInvitation,
    this.onPinAccess,
  });
  final void Function(String email, String password) onSignIn;
  final VoidCallback onRecover;
  final VoidCallback onRegister;
  final VoidCallback onGoogle;
  final VoidCallback onFacebook;
  final bool busy;
  final String? errorText;
  final VoidCallback? onInvitation;

  /// Shown only when this device remembers an adult who enrolled a PIN.
  final VoidCallback? onPinAccess;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    if (!widget.busy && _form.currentState!.validate()) {
      FocusScope.of(context).unfocus();
      widget.onSignIn(_email.text, _password.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(22, 28, 22, 24),
              child: Form(
                key: _form,
                child: AutofillGroup(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(text.loginTitle, style: TataTypography.heading),
                      const SizedBox(height: 4),
                      Text(text.loginSubtitle, style: TataTypography.subtitle),
                      const SizedBox(height: 42),
                      AccessForm(
                        email: _email,
                        password: _password,
                        busy: widget.busy,
                        onSubmit: _submit,
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: widget.busy ? null : widget.onRecover,
                          child: Text(text.forgotPassword),
                        ),
                      ),
                      if (widget.errorText != null) ...[
                        Semantics(
                          liveRegion: true,
                          child: Text(
                            widget.errorText!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      ElevatedButton(
                        onPressed: widget.busy ? null : _submit,
                        child: widget.busy
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onPrimary,
                                  semanticsLabel: text.signIn,
                                ),
                              )
                            : Text(text.signIn),
                      ),
                      const SizedBox(height: 30),
                      Row(
                        children: [
                          const Expanded(
                            child: Divider(color: TataColors.border),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              text.continueWith,
                              style: TataTypography.subtitle,
                            ),
                          ),
                          const Expanded(
                            child: Divider(color: TataColors.border),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      SocialAccessButton(
                        label: text.continueGoogle,
                        asset: 'assets/icons/google.svg',
                        iconWidth: 25.2973,
                        onPressed: widget.busy ? null : widget.onGoogle,
                      ),
                      const SizedBox(height: 12),
                      SocialAccessButton(
                        label: text.continueFacebook,
                        asset: 'assets/icons/facebook.svg',
                        iconWidth: 24,
                        onPressed: widget.busy ? null : widget.onFacebook,
                      ),
                      const SizedBox(height: 28),
                      Center(
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              text.noAccount,
                              style: const TextStyle(
                                fontSize: 13,
                                color: TataColors.muted,
                              ),
                            ),
                            TextButton(
                              onPressed: widget.busy ? null : widget.onRegister,
                              child: Text(
                                text.createAccount,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (widget.onInvitation != null)
                        Center(
                          child: TextButton(
                            onPressed: widget.busy ? null : widget.onInvitation,
                            child: Text(text.haveInvitation),
                          ),
                        ),
                      if (widget.onPinAccess != null)
                        Center(
                          child: TextButton.icon(
                            onPressed: widget.busy ? null : widget.onPinAccess,
                            icon: const Icon(Icons.dialpad, size: 18),
                            label: Text(text.signInWithPin),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
