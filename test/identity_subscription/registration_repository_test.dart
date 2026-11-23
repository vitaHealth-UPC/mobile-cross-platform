import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tata/features/identity_subscription/application/usecases/register_caregiver.dart';
import 'package:tata/features/identity_subscription/application/usecases/verify_email.dart';
import 'package:tata/features/identity_subscription/infrastructure/remote/registration_api.dart';
import 'package:tata/features/identity_subscription/infrastructure/repositories/remote_account_registration.dart';
import 'package:tata/shared/common/result/app_result.dart';
import 'package:tata/shared/infrastructure/network/api_client.dart';

import '../support/memory_session_store.dart';

void main() {
  final now = DateTime.utc(2026, 10, 27);
  Map<String, Object?> account({bool active = false}) => {
    'id': 'account-A',
    'name': 'User',
    'email': 'user@example.com',
    'status': active ? 'ACTIVE' : 'PENDING_VERIFICATION',
    'accessToken': active ? 'verification-token' : null,
    'expiresAt': active ? '2030-01-01T00:00:00Z' : null,
  };
  RemoteAccountRegistration repository(
    MemorySessionStore store,
    Future<http.Response> Function(http.Request) handler,
  ) {
    final client = ApiClient(
      baseUrl: Uri.parse('https://example.com/'),
      client: MockClient(handler),
    );
    addTearDown(client.close);
    return RemoteAccountRegistration(
      api: RegistrationApi(client),
      store: store,
      clock: () => now,
    );
  }

  test(
    'registration creates pending account without writing a session',
    () async {
      final store = MemorySessionStore();
      final repo = repository(store, (request) async {
        expect(request.url.path, '/api/v1/accounts');
        expect(request.headers.containsKey('Authorization'), isFalse);
        expect(jsonDecode(request.body), {
          'name': 'User',
          'email': 'user@example.com',
          'password': ' password ',
        });
        return http.Response(jsonEncode(account()), 201);
      });
      expect(
        await RegisterCaregiver(repo)(
          ' User ',
          ' USER@example.com ',
          ' password ',
        ),
        isA<AppSuccess<String>>().having(
          (r) => r.value,
          'account',
          'account-A',
        ),
      );
      expect(store.writes, 0);
    },
  );

  test('invalid input never sends HTTP; six digits are ASCII and password byte-limited', () async {
    var calls = 0;
    final repo = repository(MemorySessionStore(), (_) async {
      calls++;
      return http.Response('', 500);
    });
    expect(
      await RegisterCaregiver(repo)('', 'user@example.com', 'password'),
      isA<AppFailure>(),
    );
    expect(
      await RegisterCaregiver(repo)('User', 'user@example.com', 'é' * 40),
      isA<AppFailure>(),
    );
    expect(
      await VerifyEmail(repo)('account-A', 'user@example.com', '１２３４５６'),
      isA<AppFailure>(),
    );
    expect(calls, 0);
  });

  test(
    'verification persists only a matching active account and issued session',
    () async {
      final store = MemorySessionStore();
      final repo = repository(store, (request) async {
        expect(request.url.path, '/api/v1/accounts/verification');
        expect(jsonDecode(request.body), {
          'email': 'user@example.com',
          'code': '123456',
        });
        expect(request.headers.containsKey('Authorization'), isFalse);
        return http.Response(jsonEncode(account(active: true)), 200);
      });
      expect(
        await VerifyEmail(repo)('account-A', 'user@example.com', '123456'),
        isA<AppSuccess>(),
      );
      expect(store.current?.owner.id, 'account-A');
      expect(store.current?.accessToken, 'verification-token');
    },
  );

  test('foreign account, wrong email, expiry and premature credential are rejected', () async {
    for (final body in [
      {...account(active: true), 'id': 'account-B'},
      {...account(active: true), 'email': 'foreign@example.com'},
      {...account(active: true), 'expiresAt': '2020-01-01T00:00:00Z'},
      {...account(active: true), 'accessToken': ''},
    ]) {
      final store = MemorySessionStore();
      final repo = repository(
        store,
        (_) async => http.Response(jsonEncode(body), 200),
      );
      expect(
        await repo.verify('account-A', 'user@example.com', '123456'),
        isA<AppFailure>(),
      );
      expect(store.writes, 0);
    }
    final store = MemorySessionStore();
    final repo = repository(
      store,
      (_) async => http.Response(jsonEncode(account(active: true)), 201),
    );
    expect(
      await repo.register('User', 'user@example.com', 'password'),
      isA<AppFailure>(),
    );
    expect(store.writes, 0);
  });

  test(
    'duplicate, invalid and expired challenges retain distinct safe codes',
    () async {
      for (final entry in {
        'DUPLICATE_EMAIL': 409,
        'INVALID_VERIFICATION': 401,
        'VERIFICATION_EXPIRED': 410,
      }.entries) {
        final store = MemorySessionStore();
        final repo = repository(
          store,
          (_) async =>
              http.Response(jsonEncode({'title': entry.key}), entry.value),
        );
        expect(
          await repo.verify('account-A', 'user@example.com', '123456'),
          isA<AppFailure>().having((r) => r.code, 'code', entry.key),
        );
        expect(store.writes, 0);
      }
    },
  );

  test('resend accepts the exact pending account response without creating a session', () async {
    final store = MemorySessionStore();
    final repo = repository(store, (request) async {
      expect(request.url.path, '/api/v1/email-verification-requests');
      return http.Response(jsonEncode(account()), 202);
    });
    expect(
      await repo.requestVerification('account-A', 'user@example.com'),
      isA<AppSuccess>(),
    );
    expect(store.writes, 0);
  });

  test(
    'late verification cannot overwrite a changed session generation',
    () async {
      final store = MemorySessionStore();
      final pending = Completer<http.Response>();
      final started = Completer<void>();
      final repo = repository(store, (_) {
        started.complete();
        return pending.future;
      });
      final verification = repo.verify(
        'account-A',
        'user@example.com',
        '123456',
      );
      await started.future;
      await store.replace(null, expectedGeneration: store.generation);
      pending.complete(http.Response(jsonEncode(account(active: true)), 200));
      expect(
        await verification,
        isA<AppFailure>().having((r) => r.code, 'code', 'SESSION_CHANGED'),
      );
      expect(store.current, isNull);
    },
  );
}
