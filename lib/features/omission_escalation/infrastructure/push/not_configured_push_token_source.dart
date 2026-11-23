import '../../../../shared/common/result/app_result.dart';
import '../../application/ports/omission_ports.dart';
import '../../domain/value_objects/omission_push.dart';

/// Token source of a build without a push provider: the Kotlin app behaves the same when
/// `google-services.json` is missing. Registration then stays off without any error.
/// Replace it with an SDK adapter once Firebase is configured for this client.
final class NotConfiguredPushTokenSource implements DevicePushTokenSource {
  const NotConfiguredPushTokenSource();

  @override
  Future<AppResult<String?>> currentToken() async => const AppSuccess(null);
}

/// Notifier of a build without local notifications: nothing is displayed or removed.
/// Replace it with an adapter over a local notification plugin.
final class NotConfiguredOmissionNotifier implements OmissionNotifier {
  const NotConfiguredOmissionNotifier();

  @override
  Future<void> show(OmissionPush push) async {}

  @override
  Future<void> clearDisplayed() async {}
}
