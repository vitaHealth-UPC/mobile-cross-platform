import 'package:flutter/material.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/presentation/theme/tata_typography.dart';
import '../../domain/value_objects/email_address.dart';

/// Native Flutter form fields. Controllers belong to the enclosing route's lifetime.
class AccessForm extends StatefulWidget {
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
  State<AccessForm> createState() => _AccessFormState();
}

class _AccessFormState extends State<AccessForm> {
  bool _passwordVisible = false;

  @override
  void didUpdateWidget(AccessForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.busy) _passwordVisible = false;
  }

  @override
  Widget build(BuildContext context) {
    final email = widget.email;
    final password = widget.password;
    final busy = widget.busy;
    final onSubmit = widget.onSubmit;
    final text = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(text.emailLabel, style: TataTypography.label),
        const SizedBox(height: 10),
        _AccessField(
          child: TextFormField(
            key: const Key('login-email'),
            controller: email,
            enabled: !busy,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.username],
            autocorrect: false,
            style: const TextStyle(fontSize: 14, letterSpacing: 0, height: 1.2),
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
        ),
        const SizedBox(height: 20),
        Text(text.passwordLabel, style: TataTypography.label),
        const SizedBox(height: 10),
        _AccessField(
          child: TextFormField(
            key: const Key('login-password'),
            controller: password,
            enabled: !busy,
            obscureText: !_passwordVisible,
            enableSuggestions: false,
            autocorrect: false,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.password],
            style: const TextStyle(fontSize: 14, letterSpacing: 0, height: 1.2),
            decoration: InputDecoration(
              hintText: text.passwordHint,
              suffixIcon: IconButton(
                tooltip: _passwordVisible
                    ? text.hidePassword
                    : text.showPassword,
                onPressed: widget.busy
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
                value == null || value.isEmpty ? text.invalidPassword : null,
            onFieldSubmitted: (_) {
              if (!busy) onSubmit();
            },
          ),
        ),
      ],
    );
  }
}

/// Adds the design's soft elevation without replacing native field behavior.
class _AccessField extends StatelessWidget {
  const _AccessField({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(15),
      boxShadow: const [
        BoxShadow(
          color: Color(0x141A2138),
          blurRadius: 18,
          offset: Offset(0, 6),
        ),
      ],
    ),
    child: ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 58),
      child: child,
    ),
  );
}
