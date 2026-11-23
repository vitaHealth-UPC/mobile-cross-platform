import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/presentation/theme/tata_colors.dart';
import '../../../../shared/presentation/theme/tata_typography.dart';
import '../widgets/registration_form.dart';

/// Editable caregiver account and verification form matching Figma 563:1398.
/// Owns transient controllers and clears the password after account creation.
class CaregiverRegistrationScreen extends StatefulWidget {
  const CaregiverRegistrationScreen({
    super.key,
    required this.onRegister,
    required this.onVerify,
    required this.onResend,
    this.busy = false,
    this.hasAccount = false,
    this.errorText,
    this.resent = false,
  });
  final void Function(String name, String email, String password) onRegister;
  final ValueChanged<String> onVerify;
  final VoidCallback onResend;
  final bool busy;
  final bool hasAccount;
  final bool resent;
  final String? errorText;

  @override
  State<CaregiverRegistrationScreen> createState() =>
      _CaregiverRegistrationScreenState();
}

class _CaregiverRegistrationScreenState
    extends State<CaregiverRegistrationScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _code = TextEditingController();

  @override
  void didUpdateWidget(CaregiverRegistrationScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.hasAccount && !oldWidget.hasAccount) _password.clear();
    if (widget.resent && !oldWidget.resent) _code.clear();
  }

  @override
  void dispose() {
    for (final controller in [_name, _email, _password, _code]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _register() {
    if (!widget.busy && _form.currentState!.validate()) {
      FocusScope.of(context).unfocus();
      widget.onRegister(_name.text, _email.text, _password.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    return PopScope(
      canPop: !widget.busy,
      child: Scaffold(
        body: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(22, 28, 22, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(text.registrationTitle, style: TataTypography.heading),
                    const SizedBox(height: 4),
                    Text(
                      text.registrationSubtitle,
                      style: TataTypography.subtitle,
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: const LinearGradient(
                          colors: [Color(0xFFF1ECFF), Color(0xFFECF4FB)],
                        ),
                      ),
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              text.accountStep,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          SizedBox(
                            width: 72,
                            child: LinearProgressIndicator(
                              value: 1,
                              minHeight: 4,
                              color: TataColors.primary,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 20),
                          Flexible(
                            child: Text(
                              text.verificationStep,
                              style: const TextStyle(fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Form(
                      key: _form,
                      child: AutofillGroup(
                        child: RegistrationForm(
                          name: _name,
                          email: _email,
                          password: _password,
                          enabled: !widget.busy && !widget.hasAccount,
                          onSubmit: _register,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: widget.busy || widget.hasAccount
                          ? null
                          : _register,
                      child: widget.busy && !widget.hasAccount
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(text.createAccount),
                    ),
                    if (widget.hasAccount) ...[
                      const SizedBox(height: 20),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF4E2),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              text.verifyTitle,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              text.verifyExplanation,
                              style: TataTypography.subtitle,
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              key: const Key('registration-code'),
                              controller: _code,
                              enabled: !widget.busy,
                              keyboardType: TextInputType.number,
                              autofillHints: const [AutofillHints.oneTimeCode],
                              maxLength: 6,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 8,
                                color: TataColors.primary,
                              ),
                              decoration: InputDecoration(
                                labelText: text.verificationCode,
                                counterText: '',
                                filled: false,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 56),
                          backgroundColor: const Color(0xFFF1ECFF),
                          foregroundColor: TataColors.primary,
                          side: const BorderSide(color: Color(0xFFC2B5E5)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                        onPressed: widget.busy
                            ? null
                            : () => widget.onVerify(_code.text),
                        child: Text(text.verifyEmail),
                      ),
                      TextButton(
                        onPressed: widget.busy ? null : widget.onResend,
                        child: Text(text.resendCode),
                      ),
                    ],
                    if (widget.errorText != null || widget.resent) ...[
                      const SizedBox(height: 12),
                      Semantics(
                        liveRegion: true,
                        child: Text(
                          widget.errorText ?? text.codeResent,
                          style: TextStyle(
                            color: widget.errorText == null
                                ? TataColors.primary
                                : Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: widget.busy
                          ? null
                          : () => Navigator.of(context).pop(false),
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
  }
}
