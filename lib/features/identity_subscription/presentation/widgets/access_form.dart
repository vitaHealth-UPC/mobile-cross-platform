import 'package:flutter/material.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/presentation/theme/tata_typography.dart';
import '../../domain/value_objects/email_address.dart';

/// Native Flutter form fields. Controllers belong to the enclosing route's lifetime.
class AccessForm extends StatelessWidget {
  const AccessForm({
    super.key,
    required this.email,
    required this.password,
    required this.busy,
    required this.onSubmit,
  });

  final TextEditingController email;
  final TextEditingController password;
  final bool busy;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(text.emailLabel, style: TataTypography.label),
        const SizedBox(height: 10),
        TextFormField(
          key: const Key('login-email'),
          controller: email,
          enabled: !busy,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.username],
          autocorrect: false,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(hintText: text.emailHint),
          validator: (value) {
            try {
              EmailAddress(value ?? '');
              return null;
            } on ArgumentError {
              return text.invalidEmail;
            }
          },
        ),
        const SizedBox(height: 20),
        Text(text.passwordLabel, style: TataTypography.label),
        const SizedBox(height: 10),
        TextFormField(
          key: const Key('login-password'),
          controller: password,
          enabled: !busy,
          obscureText: true,
          enableSuggestions: false,
          autocorrect: false,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.password],
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(hintText: text.passwordHint),
          validator: (value) =>
              value == null || value.isEmpty ? text.invalidPassword : null,
          onFieldSubmitted: (_) {
            if (!busy) onSubmit();
          },
        ),
      ],
    );
  }
}
