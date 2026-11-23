import '../../domain/value_objects/omission_push.dart';

/// Incoming delivery and tap evidence, independent of the messaging SDK.
/// Tap payloads remain untrusted until the application authorizes their destination.
abstract interface class OmissionMessageSource {
  Future<bool> initialize();
  Stream<OmissionPush> get received;
  Stream<String> get opened;
  Future<String?> initialPayload();
}
