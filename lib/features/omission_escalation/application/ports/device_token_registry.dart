import '../../../../shared/application/session/stored_session.dart';
import '../../../../shared/common/result/app_result.dart';

/// Sends the push registration token of this device to the backend.
abstract interface class DeviceTokenRegistry {
  /// Registers [token] for the signed-in owner. When [expectedSession] is given and the
  /// stored session is no longer that one, nothing is sent.
  Future<AppResult<void>> register(
    String token, {
    StoredSession? expectedSession,
  });

  /// Removes this installation while the session that registered it is still valid.
  Future<AppResult<void>> unregister({StoredSession? expectedSession});
}
