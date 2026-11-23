import 'dart:convert';

import '../../../../shared/common/result/app_result.dart';
import '../../domain/value_objects/email_address.dart';
import '../ports/password_recovery.dart';

/// Validates email, ASCII code and password byte limits before replacing credentials.
/// Successful recovery returns an empty receipt, not an authenticated session.
final class CompletePasswordRecovery {
  const CompletePasswordRecovery(this._recovery);
  final PasswordRecovery _recovery;

  Future<AppResult<void>> call(
    String email,
    String code,
    String newPassword,
  ) async {
    final String normalized;
    try {
      normalized = EmailAddress(email).value;
    } on ArgumentError {
      return const AppFailure('INVALID_EMAIL');
    }
    if (normalized.length > 200) return const AppFailure('INVALID_EMAIL');
    if (!RegExp(r'^[0-9]{6}$').hasMatch(code)) {
      return const AppFailure('INVALID_RECOVERY_CODE');
    }
    if (newPassword.trim().isEmpty ||
        newPassword.length < 8 ||
        utf8.encode(newPassword).length > 72) {
      return const AppFailure('INVALID_PASSWORD');
    }
    return _recovery.complete(normalized, code, newPassword);
  }
}
