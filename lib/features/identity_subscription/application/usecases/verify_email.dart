import '../../../../shared/common/result/app_result.dart';
import '../../domain/entities/account_session.dart';
import '../ports/account_registration.dart';

/// Validates a six-digit ASCII challenge and requests the verified account session.
final class VerifyEmail {
  const VerifyEmail(this._registration);
  final AccountRegistration _registration;

  Future<AppResult<AccountSession>> call(
    String accountId,
    String email,
    String code,
  ) async {
    if (!RegExp(r'^[0-9]{6}$').hasMatch(code)) {
      return const AppFailure('INVALID_VERIFICATION');
    }
    return _registration.verify(accountId, email, code);
  }
}
