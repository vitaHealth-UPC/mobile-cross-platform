import '../../domain/value_objects/omission_push.dart';

/// Shows and removes the local notices of this context. The platform adapter owns channels,
/// permission and the tap payload; this context only decides whether a notice may appear.
abstract interface class OmissionNotifier {
  Future<void> show(OmissionPush push);

  /// Removes this feature's notices while retaining unrelated notifications.
  Future<void> clearDisplayed();
}
