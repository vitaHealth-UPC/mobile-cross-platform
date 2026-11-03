import '../../../../shared/common/result/app_result.dart';
import '../../domain/value_objects/email_address.dart';
import '../ports/password_recovery.dart';

/// Normalizes the recipient and requests a uniform, anonymous recovery receipt.
final class RequestPasswordRecovery {
  const RequestPasswordRecovery(this._recovery);
  final PasswordRecovery _recovery;

  Future<AppResult<void>> call(String email) async {
    final String normalized;
    try {
      normalized = EmailAddress(email).value;
    } on ArgumentError {
      return const AppFailure('INVALID_EMAIL');
    }
    if (normalized.length > 200) return const AppFailure('INVALID_EMAIL');
    return _recovery.request(normalized);
  }
}
