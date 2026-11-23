import 'dart:convert';

import '../../../../shared/common/result/app_result.dart';
import '../../domain/value_objects/email_address.dart';
import '../ports/account_registration.dart';

/// Validates account input and creates a pending account without granting access.
final class RegisterCaregiver {
  const RegisterCaregiver(this._registration);
  final AccountRegistration _registration;

  Future<AppResult<String>> call(
    String name,
    String email,
    String password,
  ) async {
    final String normalized;
    try {
      normalized = EmailAddress(email).value;
    } on ArgumentError {
      return const AppFailure('INVALID_EMAIL');
    }
    if (name.trim().isEmpty || name.trim().length > 120) {
      return const AppFailure('INVALID_NAME');
    }
    if (normalized.length > 200) return const AppFailure('INVALID_EMAIL');
    if (password.trim().isEmpty ||
        password.length < 8 ||
        utf8.encode(password).length > 72) {
      return const AppFailure('INVALID_PASSWORD');
    }
    return _registration.register(name.trim(), normalized, password);
  }
}
