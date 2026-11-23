import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tata/features/omission_escalation/infrastructure/push/firebase_push_token_source.dart';
import 'package:tata/shared/common/result/app_result.dart';

class _Settings implements NotificationSettings {
  _Settings(this.authorizationStatus);
  @override
  final AuthorizationStatus authorizationStatus;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Messaging implements FirebaseMessaging {
  AuthorizationStatus status = AuthorizationStatus.authorized;
  int tokenReads = 0;
  String? token = 'opaque-device-address';

  @override
  Future<NotificationSettings> getNotificationSettings() async =>
      _Settings(status);
  @override
  Future<String?> getToken({
    String? vapidKey,
    String? serviceWorkerScriptPath,
  }) async {
    tokenReads++;
    return token;
  }

  @override
  Stream<String> get onTokenRefresh => Stream.value('rotated-address');
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test(
    'rotation after permission withdrawal does not expose a new address',
    () async {
      final sdk = _Messaging()..status = AuthorizationStatus.denied;
      final source = FirebasePushTokenSource(
        supported: true,
        messaging: () async => sdk,
      );
      expect(await source.refreshedTokens.toList(), isEmpty);
      expect(sdk.tokenReads, 0);
    },
  );

  test('unsupported platforms do not initialize Firebase', () async {
    final source = FirebasePushTokenSource(
      supported: false,
      messaging: () => throw StateError('must not initialize'),
    );
    expect((await source.currentToken() as AppSuccess<String?>).value, isNull);
  });

  test('denied permission never reads or registers an SDK address', () async {
    final sdk = _Messaging()..status = AuthorizationStatus.denied;
    final source = FirebasePushTokenSource(
      supported: true,
      messaging: () async => sdk,
    );
    expect((await source.currentToken() as AppSuccess<String?>).value, isNull);
    expect(sdk.tokenReads, 0);
  });

  test(
    'authorized addresses and SDK rotations reach the registry boundary',
    () async {
      final sdk = _Messaging();
      final source = FirebasePushTokenSource(
        supported: true,
        messaging: () async => sdk,
      );
      expect(
        (await source.currentToken() as AppSuccess<String?>).value,
        sdk.token,
      );
      expect(await source.refreshedTokens.first, 'rotated-address');
    },
  );

  test('missing address remains retryable', () async {
    final sdk = _Messaging()..token = null;
    final source = FirebasePushTokenSource(
      supported: true,
      messaging: () async => sdk,
    );
    expect(
      (await source.currentToken() as AppFailure<String?>).code,
      'PUSH_TOKEN_UNAVAILABLE',
    );
  });

  test('provider diagnostics never enter application failures', () async {
    final source = FirebasePushTokenSource(
      supported: true,
      messaging: () async => throw FirebaseException(
        plugin: 'firebase_messaging',
        code: 'unavailable',
        message: 'private-provider-details',
      ),
    );
    final result = await source.currentToken();
    expect((result as AppFailure<String?>).code, 'PUSH_TOKEN_UNAVAILABLE');
    expect(result.toString(), isNot(contains('private-provider-details')));
  });
}
