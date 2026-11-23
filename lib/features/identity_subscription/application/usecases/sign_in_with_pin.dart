import '../../../../shared/common/result/app_result.dart';
import '../../domain/entities/account_session.dart';
import '../../domain/value_objects/pin_code.dart';
import '../ports/pin_access.dart';

/// Validates the adult reference and PIN format before requesting PIN access.
final class SignInWithPin {
  const SignInWithPin(this._access);
  final PinAccess _access;

  Future<AppResult<AccountSession>> call(
    String olderAdultId,
    String pin,
  ) async {
    if (olderAdultId.trim().isEmpty || olderAdultId != olderAdultId.trim()) {
      return const AppFailure('INVALID_RESPONSE');
    }
    final PinCode code;
    try {
      code = PinCode(pin);
    } on ArgumentError {
      return const AppFailure('INVALID_PIN_FORMAT');
    }
    return _access.signIn(olderAdultId, code);
  }
}
