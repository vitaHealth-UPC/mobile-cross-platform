import 'dart:convert';

import '../../../../shared/common/result/app_result.dart';
import '../../domain/entities/account_session.dart';
import '../../domain/repositories/session_repository.dart';
import '../../domain/value_objects/email_address.dart';

/// Validates and normalizes email while preserving the exact password supplied by the user.
final class SignIn {
  const SignIn(this._repository);
  final SessionRepository _repository;

  Future<AppResult<AccountSession>> call(String email, String password) async {
    final String normalized;
    try {
      normalized = EmailAddress(email).value;
    } on ArgumentError {
      return const AppFailure('INVALID_EMAIL');
    }
    if (password.isEmpty || utf8.encode(password).length > 72) {
      return const AppFailure('INVALID_PASSWORD');
    }
    return _repository.signIn(normalized, password);
  }
}
