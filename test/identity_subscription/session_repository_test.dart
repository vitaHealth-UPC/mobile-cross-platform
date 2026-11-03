import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tata/features/identity_subscription/application/usecases/sign_in.dart';
import 'package:tata/features/identity_subscription/infrastructure/remote/session_api.dart';
import 'package:tata/features/identity_subscription/infrastructure/repositories/remote_session_repository.dart';
import 'package:tata/shared/application/session/session_owner.dart';
import 'package:tata/shared/application/session/session_store.dart';
import 'package:tata/shared/application/session/stored_session.dart';
import 'package:tata/shared/common/result/app_result.dart';
import 'package:tata/shared/infrastructure/network/api_client.dart';

import '../support/memory_session_store.dart';

void main() {
  final now = DateTime.utc(2026, 10, 27);
  Map<String, Object?> credential() => {
    'accountId': 'caregiver-A',
    'olderAdultId': null,
    'accessToken': 'token-A',
    'expiresAt': '2030-01-01T00:00:00Z',
  };
  StoredSession saved() => StoredSession(
    accessToken: 'token-A',
    expiresAt: DateTime.utc(2030),
    owner: SessionOwner('caregiver-A', SessionRole.caregiver),
  );

  RemoteSessionRepository repository(
    SessionStore store,
    Future<http.Response> Function(http.Request) handler,
  ) {
    final client = ApiClient(
      baseUrl: Uri.parse('https://example.com/'),
      client: MockClient(handler),
    );
    addTearDown(client.close);
    return RemoteSessionRepository(
      api: SessionApi(client),
      store: store,
      clock: () => now,
    );
  }

  test('sign-in normalizes email but preserves password and stores acknowledged credential', () async {
    final store = MemorySessionStore();
    final repo = repository(store, (request) async {
      expect(request.url.path, '/api/v1/sessions');
      expect(request.headers.containsKey('Authorization'), isFalse);
      expect(jsonDecode(request.body), {
        'email': 'user@example.com',
        'password': ' password ',
      });
      return http.Response(jsonEncode(credential()), 200);
    });
    final result = await SignIn(repo)(' USER@example.com ', ' password ');
    expect(result, isA<AppSuccess>());
    expect(store.current?.owner.id, 'caregiver-A');
    expect(store.current.toString(), isNot(contains('token-A')));
  });

  test('validation performs no HTTP request or session mutation', () async {
    final store = MemorySessionStore();
    var calls = 0;
    final repo = repository(store, (_) async {
      calls++;
      return http.Response('{}', 500);
    });
    expect(await SignIn(repo)('not-email', 'password'), isA<AppFailure>());
    expect(await SignIn(repo)('a@example.com', 'é' * 37), isA<AppFailure>());
    expect(calls, 0);
    expect(store.writes, 0);
  });

  for (final malformed in [
    'ambiguous-owner',
    'expired',
    'missing-offset',
    'blank-token',
    'unexpected-status',
  ]) {
    test('sign-in rejects $malformed without persisting a session', () async {
      final store = MemorySessionStore();
      final body = credential();
      if (malformed == 'ambiguous-owner') body['olderAdultId'] = 'adult-B';
      if (malformed == 'expired') body['expiresAt'] = now.toIso8601String();
      if (malformed == 'missing-offset') {
        body['expiresAt'] = '2030-01-01T00:00:00';
      }
      if (malformed == 'blank-token') body['accessToken'] = ' ';
      final repo = repository(
        store,
        (_) async => http.Response(
          jsonEncode(body),
          malformed == 'unexpected-status' ? 201 : 200,
        ),
      );
      expect(await repo.signIn('a@example.com', 'password'), isA<AppFailure>());
      expect(store.writes, 0);
    });
  }

  test('restore validates current subject and role instead of trusting cached identity', () async {
    for (final body in [
      {'subjectId': 'caregiver-A', 'role': 'OLDER_ADULT'},
      {'subjectId': 'other', 'role': 'CAREGIVER'},
    ]) {
      final store = MemorySessionStore(saved());
      final repo = repository(
        store,
        (_) async => http.Response(jsonEncode(body), 200),
      );
      final result = await repo.restore();
      expect(result, isA<AppFailure>());
      expect(store.current, isNull);
    }
  });

  test(
    'revocation clears cached credentials even when error body is HTML',
    () async {
      final store = MemorySessionStore(saved());
      final repo = repository(
        store,
        (_) async => http.Response('<html>unauthorized</html>', 401),
      );
      expect(
        await repo.restore(),
        isA<AppSuccess>().having((v) => v.value, 'anonymous', isNull),
      );
      expect(store.current, isNull);
    },
  );

  test(
    'server outage is a failure and never authenticated cache fallback',
    () async {
      final store = MemorySessionStore(saved());
      final repo = repository(store, (_) async => http.Response('{}', 503));
      expect(await repo.restore(), isA<AppFailure>());
      expect(store.current, isNotNull);
    },
  );

  test('logout supersedes an in-flight sign-in and late response cannot restore the account', () async {
    final pending = Completer<http.Response>();
    final started = Completer<void>();
    final store = MemorySessionStore();
    final repo = repository(store, (_) {
      started.complete();
      return pending.future;
    });
    final login = repo.signIn('a@example.com', 'password');
    await started.future;
    expect(await repo.signOut(), isA<AppSuccess>());
    pending.complete(http.Response(jsonEncode(credential()), 200));
    expect(
      await login,
      isA<AppFailure>().having((v) => v.code, 'code', 'SESSION_CHANGED'),
    );
    expect(store.current, isNull);
  });

  test(
    'logout revokes with the captured bearer after clearing local access',
    () async {
      final store = MemorySessionStore(saved());
      final repo = repository(store, (request) async {
        expect(store.current, isNull);
        expect(request.method, 'DELETE');
        expect(request.headers['Authorization'], 'Bearer token-A');
        return http.Response('', 204);
      });
      expect(await repo.signOut(), isA<AppSuccess>());
    },
  );

  test(
    'logout attempts remote revocation even when secure deletion fails',
    () async {
      final store = _FailingDeleteStore(saved());
      var revoked = false;
      final repo = repository(store, (request) async {
        expect(store.current, isNull);
        expect(request.method, 'DELETE');
        expect(request.headers['Authorization'], 'Bearer token-A');
        revoked = true;
        return http.Response('', 204);
      });
      expect(
        await repo.signOut(),
        isA<AppFailure>().having(
          (failure) => failure.code,
          'code',
          'SESSION_STORAGE_UNAVAILABLE',
        ),
      );
      expect(revoked, isTrue);
    },
  );
}

/// Models the adapter's in-memory invalidation followed by a platform I/O error.
final class _FailingDeleteStore implements SessionStore {
  _FailingDeleteStore(this.current);

  @override
  StoredSession? current;
  @override
  int generation = 0;
  @override
  Future<void> initialize() async {}
  @override
  Future<bool> replace(
    StoredSession? session, {
    required int expectedGeneration,
  }) async {
    if (generation != expectedGeneration) return false;
    generation++;
    current = null;
    throw Exception('Platform storage is unavailable');
  }
}
