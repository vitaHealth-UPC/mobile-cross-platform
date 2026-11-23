import '../../../../shared/common/result/app_result.dart';
import '../../domain/entities/account_session.dart';

/// Pending account creation never grants access; verification must issue a session.
abstract interface class AccountRegistration {
  /// Returns the pending account identifier without persisting a session.
  Future<AppResult<String>> register(
    String name,
    String email,
    String password,
  );

  /// Verifies [code] for the expected [accountId] and [email] before storing access.
  Future<AppResult<AccountSession>> verify(
    String accountId,
    String email,
    String code,
  );

  /// Renews the challenge when the receipt matches the pending account.
  Future<AppResult<void>> requestVerification(String accountId, String email);
}
