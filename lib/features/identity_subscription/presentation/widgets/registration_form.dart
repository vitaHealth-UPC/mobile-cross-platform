import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/presentation/theme/tata_typography.dart';
import '../../domain/value_objects/email_address.dart';

/// Native account fields with local validation and parent-owned controllers.
class RegistrationForm extends StatefulWidget {
  const RegistrationForm({
    super.key,
    required this.name,
    required this.email,
    required this.password,
    required this.enabled,
    required this.onSubmit,
  });
  final TextEditingController name;
  final TextEditingController email;
  final TextEditingController password;
  final bool enabled;
  final VoidCallback onSubmit;

  @override
  State<RegistrationForm> createState() => _RegistrationFormState();
}

class _RegistrationFormState extends State<RegistrationForm> {
  bool _passwordVisible = false;

  @override
  void didUpdateWidget(RegistrationForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.enabled) _passwordVisible = false;
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.name;
    final email = widget.email;
    final password = widget.password;
    final enabled = widget.enabled;
    final onSubmit = widget.onSubmit;
    final text = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _field(
          label: text.nameLabel,
          field: TextFormField(
            key: const Key('registration-name'),
            controller: name,
            enabled: enabled,
            textCapitalization: TextCapitalization.words,
            autofillHints: const [AutofillHints.name],
            textInputAction: TextInputAction.next,
            style: const TextStyle(fontSize: 14, letterSpacing: 0, height: 1.2),
            decoration: _decoration(text.nameHint),
            validator: (value) =>
                value == null ||
                    value.trim().isEmpty ||
                    value.trim().length > 120
                ? text.invalidName
                : null,
          ),
        ),
        const SizedBox(height: 2),
        _field(
          label: text.emailLabel,
          field: TextFormField(
            key: const Key('registration-email'),
            controller: email,
            enabled: enabled,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            autofillHints: const [AutofillHints.newUsername],
            textInputAction: TextInputAction.next,
            style: const TextStyle(fontSize: 14, letterSpacing: 0, height: 1.2),
            decoration: _decoration(text.emailHint),
            validator: (value) {
              try {
                return EmailAddress(value ?? '').value.length <= 200
                    ? null
                    : text.invalidEmail;
              } on ArgumentError {
                return text.invalidEmail;
              }
            },
          ),
        ),
        const SizedBox(height: 2),
        _field(
          label: text.passwordLabel,
          field: TextFormField(
            key: const Key('registration-password'),
            controller: password,
            enabled: enabled,
            obscureText: !_passwordVisible,
            autocorrect: false,
            enableSuggestions: false,
            autofillHints: const [AutofillHints.newPassword],
            textInputAction: TextInputAction.done,
            style: const TextStyle(fontSize: 14, letterSpacing: 0, height: 1.2),
            decoration: _decoration(text.registrationPasswordHint).copyWith(
              suffixIcon: IconButton(
                tooltip: _passwordVisible
                    ? text.hidePassword
                    : text.showPassword,
                onPressed: !widget.enabled
                    ? null
                    : () =>
                          setState(() => _passwordVisible = !_passwordVisible),
                icon: Icon(
                  _passwordVisible
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 22,
                ),
              ),
            ),
            validator: (value) =>
                value == null ||
                    value.trim().isEmpty ||
                    value.length < 8 ||
                    utf8.encode(value).length > 72
                ? text.registrationPasswordError
                : null,
            onFieldSubmitted: (_) {
              if (enabled) onSubmit();
            },
          ),
        ),
      ],
    );
  }

  InputDecoration _decoration(String hint) => InputDecoration(
    hintText: hint,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
  );

  Widget _field({required String label, required Widget field}) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: TataTypography.label),
      const SizedBox(height: 8),
      DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          boxShadow: const [
            BoxShadow(
              color: Color(0x141A2138),
              offset: Offset(0, 6),
              blurRadius: 18,
            ),
          ],
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 58),
          child: field,
        ),
      ),
    ],
  );
}
