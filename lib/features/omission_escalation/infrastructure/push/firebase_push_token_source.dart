import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../../../shared/common/result/app_result.dart';
import '../../../../shared/infrastructure/firebase/firebase_runtime.dart';
import '../../application/ports/device_push_token_source.dart';

/// Reads native FCM addresses only after notification permission is granted.
/// Addresses stay inside the SDK and authenticated registry, never diagnostics.
final class FirebasePushTokenSource implements DevicePushTokenSource {
  FirebasePushTokenSource({
    Future<FirebaseMessaging> Function()? messaging,
    bool? supported,
  }) : _messaging = messaging ?? _nativeMessaging,
       _supported =
           supported ??
           (!kIsWeb &&
               (defaultTargetPlatform == TargetPlatform.android ||
                   defaultTargetPlatform == TargetPlatform.iOS));

  final Future<FirebaseMessaging> Function() _messaging;
  final bool _supported;

  static Future<FirebaseMessaging> _nativeMessaging() async {
    await FirebaseRuntime.initialize();
    return FirebaseMessaging.instance;
  }

  /// SDK rotation is consumed by the host for the session currently in force.
  Stream<String> get refreshedTokens async* {
    if (!_supported) return;
    final messaging = await _messaging();
    // Tata currently registers FCM tokens, not the SDK 17 installation-ID contract.
    // ignore: deprecated_member_use
    yield* messaging.onTokenRefresh;
  }

  @override
  Future<AppResult<String?>> currentToken() async {
    if (!_supported) return const AppSuccess(null);
    try {
      final messaging = await _messaging();
      var settings = await messaging.getNotificationSettings();
      if (settings.authorizationStatus == AuthorizationStatus.notDetermined) {
        settings = await messaging.requestPermission();
      }
      if (settings.authorizationStatus != AuthorizationStatus.authorized &&
          settings.authorizationStatus != AuthorizationStatus.provisional) {
        return const AppSuccess(null);
      }
      // Keep the existing server token protocol until its sender supports FIDs.
      // ignore: deprecated_member_use
      final token = await messaging.getToken();
      if (token == null || token.isEmpty) {
        return const AppFailure('PUSH_TOKEN_UNAVAILABLE');
      }
      return AppSuccess(token);
    } on MissingPluginException {
      return const AppFailure('PUSH_NOT_CONFIGURED');
    } on FirebaseException catch (error) {
      return AppFailure(
        error.code == 'no-app' || error.code == 'core/not-initialized'
            ? 'PUSH_NOT_CONFIGURED'
            : 'PUSH_TOKEN_UNAVAILABLE',
      );
    } on Exception {
      return const AppFailure('PUSH_TOKEN_UNAVAILABLE');
    }
  }
}
