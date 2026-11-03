import '../../../../shared/common/result/app_result.dart';
import '../../domain/entities/account_session.dart';
import '../../domain/value_objects/pin_code.dart';

/// Adult PIN enrollment and PIN-based access against the Tata backend.
abstract interface class PinAccess {
  /// Enrolls [pin] for the adult of the captured full adult session.
  /// Fails with `PIN_ALREADY_REGISTERED` when the adult already has a PIN.
  Future<AppResult<void>> register(PinCode pin);

  /// Authenticates [olderAdultId] with [pin] and stores the adult session only
  /// after the current-session check confirms its relationship scope.
  Future<AppResult<AccountSession>> signIn(String olderAdultId, PinCode pin);
}
