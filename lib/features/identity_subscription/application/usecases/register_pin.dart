import '../../../../shared/common/result/app_result.dart';
import '../../domain/value_objects/pin_code.dart';
import '../ports/pin_access.dart';

/// Validates the PIN format locally before asking the backend to enroll it.
final class RegisterPin {
  const RegisterPin(this._access);
  final PinAccess _access;

  Future<AppResult<void>> call(String pin) async {
    final PinCode code;
    try {
      code = PinCode(pin);
    } on ArgumentError {
      return const AppFailure('INVALID_PIN_FORMAT');
    }
    return _access.register(code);
  }
}
