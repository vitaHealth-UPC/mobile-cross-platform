import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tata/features/identity_subscription/application/usecases/register_pin.dart';
import 'package:tata/features/identity_subscription/application/usecases/sign_in_with_pin.dart';
import 'package:tata/features/identity_subscription/infrastructure/remote/pin_api.dart';
import 'package:tata/features/identity_subscription/infrastructure/repositories/remote_pin_access.dart';
import 'package:tata/shared/application/session/session_owner.dart';
import 'package:tata/shared/application/session/stored_session.dart';
import 'package:tata/shared/common/result/app_result.dart';
import 'package:tata/shared/infrastructure/network/api_client.dart';

import '../support/memory_session_store.dart';

void main() {
  final now = DateTime.utc(2026, 11, 3, 12);
  StoredSession adult({SessionRole role = SessionRole.olderAdult}) =>
      StoredSession(
        accessToken: 'adult-token',
        expiresAt: DateTime.utc(2030),
        owner: SessionOwner('adult-A', role, careLinkId: 'link-A'),
      );
  http.Response problem(int status, String code) =>
      http.Response(jsonEncode({'title': code, 'status': status}), status);

  RemotePinAccess access(
    MemorySessionStore store,
    Future<http.Response> Function(http.Request) handler,
  ) {
    final client = ApiClient(
      baseUrl: Uri.parse('https://example.com/'),
      client: MockClient(handler),
    );
    addTearDown(client.close);
    return RemotePinAccess(api: PinApi(client), store: store, clock: () => now);
  }

  group('PIN enrollment', () {
    test(
      'sends the adult session owner and bearer, never a caller-chosen adult',
      () async {
        final store = MemorySessionStore(adult());
        final repo = access(store, (request) async {
          expect(request.url.path, '/api/v1/pin-credentials');
          expect(request.headers['Authorization'], 'Bearer adult-token');
          expect(jsonDecode(request.body), {
            'olderAdultId': 'adult-A',
            'pin': '2468',
          });
          return http.Response('', 201);
        });
        expect(await RegisterPin(repo)('2468'), isA<AppSuccess<void>>());
        expect(store.writes, 0);
      },
    );

    test('rejects malformed PINs before any request', () async {
      var calls = 0;
      final repo = access(MemorySessionStore(adult()), (_) async {
        calls++;
        return http.Response('', 201);
      });
      for (final pin in ['123', '12345', '12a4', '١٢٣٤', ' 1234']) {
        final result = await RegisterPin(repo)(pin);
        expect((result as AppFailure).code, 'INVALID_PIN_FORMAT');
      }
      expect(calls, 0);
    });

    test('restricted setup sessions cannot enroll a PIN', () async {
      var calls = 0;
      final repo = access(
        MemorySessionStore(adult(role: SessionRole.linkSetup)),
        (_) async {
          calls++;
          return http.Response('', 201);
        },
      );
      final result = await RegisterPin(repo)('2468');
      expect((result as AppFailure).code, 'ACCESS_DENIED');
      expect(calls, 0);
    });

    test('duplicate enrollment surfaces its stable code', () async {
      final repo = access(
        MemorySessionStore(adult()),
        (_) async => problem(409, 'PIN_ALREADY_REGISTERED'),
      );
      final result = await RegisterPin(repo)('2468');
      expect((result as AppFailure).code, 'PIN_ALREADY_REGISTERED');
    });

    test('a rejected bearer clears the stored adult session', () async {
      final store = MemorySessionStore(adult());
      final repo = access(store, (_) async => http.Response('', 401));
      final result = await RegisterPin(repo)('2468');
      expect((result as AppFailure).code, 'AUTHENTICATION_REQUIRED');
      expect(store.current, isNull);
    });
  });

  group('PIN access', () {
    test(
      'stores the adult session only after current confirms its care link',
      () async {
        final store = MemorySessionStore();
        final paths = <String>[];
        final repo = access(store, (request) async {
          paths.add(request.url.path);
          if (request.url.path == '/api/v1/pin-sessions') {
            expect(request.headers.containsKey('Authorization'), isFalse);
            expect(jsonDecode(request.body), {
              'olderAdultId': 'adult-A',
              'pin': '2468',
            });
            return http.Response(
              jsonEncode({
                'olderAdultId': 'adult-A',
                'accessToken': 'pin-token',
                'expiresAt': '2026-11-04T00:00:00Z',
              }),
              200,
            );
          }
          expect(request.headers['Authorization'], 'Bearer pin-token');
          return http.Response(
            jsonEncode({
              'subjectId': 'adult-A',
              'role': 'OLDER_ADULT',
              'expiresAt': '2026-11-04T00:00:00Z',
              'careLinkId': 'link-A',
            }),
            200,
          );
        });
        final result = await SignInWithPin(repo)('adult-A', '2468');
        expect(result, isA<AppSuccess>());
        expect(paths, ['/api/v1/pin-sessions', '/api/v1/sessions/current']);
        expect(
          store.current?.owner,
          SessionOwner('adult-A', SessionRole.olderAdult, careLinkId: 'link-A'),
        );
      },
    );

    for (final (status, code) in [
      (401, 'INVALID_PIN'),
      (403, 'PIN_LOCKED'),
      (404, 'PIN_NOT_FOUND'),
    ]) {
      test('maps $code without storing a session', () async {
        final store = MemorySessionStore();
        final repo = access(store, (_) async => problem(status, code));
        final result = await SignInWithPin(repo)('adult-A', '2468');
        expect((result as AppFailure).code, code);
        expect(store.writes, 0);
      });
    }

    test(
      'a missing confirmed link is reported as unavailable PIN access',
      () async {
        final repo = access(
          MemorySessionStore(),
          (_) async => problem(400, 'VALIDATION_ERROR'),
        );
        final result = await SignInWithPin(repo)('adult-A', '2468');
        expect((result as AppFailure).code, 'PIN_ACCESS_UNAVAILABLE');
      },
    );

    test('a credential for another adult or role is never stored', () async {
      for (final current in [
        {'subjectId': 'adult-B', 'role': 'OLDER_ADULT', 'careLinkId': 'link-B'},
        {'subjectId': 'adult-A', 'role': 'LINK_SETUP', 'careLinkId': 'link-A'},
        {'subjectId': 'adult-A', 'role': 'OLDER_ADULT', 'careLinkId': null},
      ]) {
        final store = MemorySessionStore();
        final repo = access(store, (request) async {
          if (request.url.path == '/api/v1/pin-sessions') {
            return http.Response(
              jsonEncode({
                'olderAdultId': 'adult-A',
                'accessToken': 'pin-token',
                'expiresAt': '2026-11-04T00:00:00Z',
              }),
              200,
            );
          }
          return http.Response(jsonEncode(current), 200);
        });
        final result = await SignInWithPin(repo)('adult-A', '2468');
        expect((result as AppFailure).code, 'INVALID_RESPONSE');
        expect(store.writes, 0);
      }
    });

    test('a response that arrives after another actor signed in is dropped', () async {
      final store = MemorySessionStore();
      final repo = access(store, (request) async {
        // Another flow replaces the session while the PIN request is in flight.
        await store.replace(
          StoredSession(
            accessToken: 'caregiver-token',
            expiresAt: DateTime.utc(2030),
            owner: SessionOwner('caregiver-A', SessionRole.caregiver),
          ),
          expectedGeneration: store.generation,
        );
        return http.Response(
          jsonEncode({
            'olderAdultId': 'adult-A',
            'accessToken': 'pin-token',
            'expiresAt': '2026-11-04T00:00:00Z',
          }),
          200,
        );
      });
      final result = await SignInWithPin(repo)('adult-A', '2468');
      expect((result as AppFailure).code, 'SESSION_CHANGED');
      expect(store.current?.owner.id, 'caregiver-A');
    });
  });
}
