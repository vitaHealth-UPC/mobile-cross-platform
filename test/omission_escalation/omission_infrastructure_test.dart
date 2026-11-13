import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tata/features/omission_escalation/infrastructure/local/push_local_stores.dart';
import 'package:tata/features/omission_escalation/infrastructure/remote/push_device_api.dart';
import 'package:tata/features/omission_escalation/infrastructure/repositories/remote_device_token_registry.dart';
import 'package:tata/shared/application/session/session_owner.dart';
import 'package:tata/shared/application/session/stored_session.dart';
import 'package:tata/shared/common/result/app_result.dart';
import 'package:tata/shared/infrastructure/network/api_client.dart';

import '../support/memory_session_store.dart';

const _installation = '3f2a9c1e-6b7d-4e8f-9a0b-1c2d3e4f5a6b';

void main() {
  StoredSession caregiver({String token = 'token-c'}) => StoredSession(
    accessToken: token,
    expiresAt: DateTime.utc(2030),
    owner: SessionOwner('caregiver-1', SessionRole.caregiver),
  );

  RemoteDeviceTokenRegistry registryFor(
    MemorySessionStore store,
    Future<http.Response> Function(http.Request) handler,
  ) {
    final client = ApiClient(
      baseUrl: Uri.parse('https://example.com/'),
      client: MockClient(handler),
    );
    addTearDown(client.close);
    return RemoteDeviceTokenRegistry(
      api: PushDeviceApi(client),
      store: store,
      installationId: _installation,
    );
  }

  http.Response receipt([String id = _installation]) => http.Response(
    jsonEncode({'installationId': id, 'updatedAt': '2030-01-01T00:00:00Z'}),
    200,
  );

  group('device registration', () {
    test(
      'sends only the token to this installation with the captured bearer',
      () async {
        final store = MemorySessionStore(caregiver());
        late http.Request seen;
        final registry = registryFor(store, (request) async {
          seen = request;
          return receipt();
        });
        final result = await registry.register(
          'fcm-token',
          expectedSession: caregiver(),
        );
        expect(result, isA<AppSuccess<void>>());
        expect(seen.method, 'PUT');
        expect(seen.url.path, '/api/v1/push-devices/$_installation');
        expect(seen.headers['Authorization'], 'Bearer token-c');
        expect(jsonDecode(seen.body), {'token': 'fcm-token'});
      },
    );

    test('an unusable token never reaches the network', () async {
      var calls = 0;
      final registry = registryFor(MemorySessionStore(caregiver()), (_) async {
        calls++;
        return receipt();
      });
      for (final token in ['', '   ', 'x' * 4097]) {
        final result = await registry.register(token);
        expect((result as AppFailure<void>).code, 'INVALID_DEVICE_TOKEN');
      }
      expect(calls, 0);
    });

    test('a request meant for another session is not sent', () async {
      var calls = 0;
      final registry = registryFor(
        MemorySessionStore(caregiver(token: 'new')),
        (_) async {
          calls++;
          return receipt();
        },
      );
      final result = await registry.register(
        'fcm-token',
        expectedSession: caregiver(token: 'old'),
      );
      expect((result as AppFailure<void>).code, 'SESSION_CHANGED');
      expect(calls, 0);
    });

    test('a link setup session cannot register a device', () async {
      final setup = StoredSession(
        accessToken: 'token-s',
        expiresAt: DateTime.utc(2030),
        owner: SessionOwner('adult-1', SessionRole.linkSetup, careLinkId: 'l'),
      );
      var calls = 0;
      final registry = registryFor(MemorySessionStore(setup), (_) async {
        calls++;
        return receipt();
      });
      final result = await registry.register('fcm-token');
      expect((result as AppFailure<void>).code, 'ACCESS_DENIED');
      expect(calls, 0);
    });

    test('validates the receipt and maps the status codes', () async {
      Future<String> codeFor(http.Response response) async {
        final registry = registryFor(
          MemorySessionStore(caregiver()),
          (_) async => response,
        );
        final result = await registry.register('fcm-token');
        return switch (result) {
          AppFailure(:final code) => code,
          AppSuccess() => 'OK',
        };
      }

      expect(await codeFor(receipt()), 'OK');
      expect(
        await codeFor(receipt('another-installation')),
        'INVALID_RESPONSE',
      );
      expect(
        await codeFor(
          http.Response(jsonEncode({'installationId': _installation}), 200),
        ),
        'INVALID_RESPONSE',
      );
      expect(await codeFor(http.Response('', 400)), 'INVALID_DEVICE_TOKEN');
      expect(await codeFor(http.Response('', 403)), 'ACCESS_DENIED');
      expect(await codeFor(http.Response('', 429)), 'RATE_LIMITED');
      expect(await codeFor(http.Response('', 500)), 'REQUEST_FAILED');
    });

    test('a rejected credential clears the session it came from', () async {
      final store = MemorySessionStore(caregiver());
      final registry = registryFor(store, (_) async => http.Response('', 401));
      final result = await registry.register('fcm-token');
      expect((result as AppFailure<void>).code, 'AUTHENTICATION_REQUIRED');
      expect(store.value, isNull);
    });

    test('unregistering expects an empty 204', () async {
      late http.Request seen;
      final registry = registryFor(MemorySessionStore(caregiver()), (
        request,
      ) async {
        seen = request;
        return http.Response('', 204);
      });
      expect(await registry.unregister(), isA<AppSuccess<void>>());
      expect(seen.method, 'DELETE');
      expect(seen.url.path, '/api/v1/push-devices/$_installation');
      expect(seen.headers['Authorization'], 'Bearer token-c');

      final unexpected = registryFor(
        MemorySessionStore(caregiver()),
        (_) async => http.Response('{}', 200),
      );
      expect(
        ((await unexpected.unregister()) as AppFailure<void>).code,
        'INVALID_RESPONSE',
      );
      final missing = registryFor(
        MemorySessionStore(caregiver()),
        (_) async => http.Response('', 404),
      );
      expect(
        ((await missing.unregister()) as AppFailure<void>).code,
        'REQUEST_FAILED',
      );
    });

    test('a registry needs a UUID installation', () {
      final client = ApiClient(
        baseUrl: Uri.parse('https://example.com/'),
        client: MockClient((_) async => receipt()),
      );
      addTearDown(client.close);
      expect(
        () => RemoteDeviceTokenRegistry(
          api: PushDeviceApi(client),
          store: MemorySessionStore(),
          installationId: 'not-a-uuid',
        ),
        throwsArgumentError,
      );
    });
  });

  group('local stores', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('followed targets survive a restart of the store', () async {
      await SharedPreferencesPushTargetStore().rememberCaregiver('a1', 'c1');
      await SharedPreferencesPushTargetStore().rememberOlderAdult('a1', 'Ana');
      final fresh = SharedPreferencesPushTargetStore();
      expect(await fresh.caregiverFor('a1'), 'c1');
      expect(await fresh.olderAdultName('a1'), 'Ana');
      expect(await fresh.caregiverFor('a2'), isNull);
      expect(await fresh.olderAdultName('a2'), isNull);
    });

    test('the installation identity is a stable random UUID v4', () async {
      final first = await SharedPreferencesPushInstallationStore()
          .getOrCreate();
      expect(
        first,
        matches(
          RegExp(
            r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
          ),
        ),
      );
      expect(
        await SharedPreferencesPushInstallationStore().getOrCreate(),
        first,
      );
    });

    test('concurrent first reads agree on one identity', () async {
      final store = SharedPreferencesPushInstallationStore();
      final ids = await Future.wait([store.getOrCreate(), store.getOrCreate()]);
      expect(ids[0], ids[1]);
    });

    test('a corrupted stored identity is replaced', () async {
      SharedPreferences.setMockInitialValues({
        'tata.push.installation': 'oops',
      });
      final id = await SharedPreferencesPushInstallationStore().getOrCreate();
      expect(id, isNot('oops'));
      expect(await SharedPreferencesPushInstallationStore().getOrCreate(), id);
    });
  });
}
