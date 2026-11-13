import '../../../../shared/application/session/stored_session.dart';
import '../../../../shared/common/result/app_result.dart';
import '../../domain/value_objects/omission_push.dart';

/// Reads the push SDK's current token; a null value means this build has no push
/// configuration, which is not an error.
abstract interface class DevicePushTokenSource {
  Future<AppResult<String?>> currentToken();
}

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

/// Who this device follows, so a tapped notification can open the right screen.
/// It stores identifiers and the display name the screens already show, no health data.
abstract interface class PushTargetStore {
  Future<void> rememberCaregiver(String olderAdultId, String caregiverId);
  Future<void> rememberOlderAdult(String olderAdultId, String olderAdultName);
  Future<String?> caregiverFor(String olderAdultId);
  Future<String?> olderAdultName(String olderAdultId);
}

/// Shows and removes the local notices of this context. The platform adapter owns channels,
/// permission and the tap payload; this context only decides whether a notice may appear.
abstract interface class OmissionNotifier {
  Future<void> show(OmissionPush push);

  /// Removes this feature's notices while retaining unrelated notifications.
  Future<void> clearDisplayed();
}
