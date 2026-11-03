import '../../../../shared/common/result/app_result.dart';
import '../ports/account_registration.dart';

/// Requests a renewed challenge for the account created by this registration flow.
final class RequestVerification {
  const RequestVerification(this._registration);
  final AccountRegistration _registration;

  Future<AppResult<void>> call(String accountId, String email) =>
      _registration.requestVerification(accountId, email);
}
