import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tata/features/care_link/application/usecases/generate_linking_code.dart';
import 'package:tata/features/care_link/application/usecases/register_older_adult.dart';
import 'package:tata/features/care_link/infrastructure/remote/care_link_api.dart';
import 'package:tata/features/care_link/infrastructure/repositories/remote_care_link_repository.dart';
import 'package:tata/shared/application/session/session_owner.dart';
import 'package:tata/shared/application/session/stored_session.dart';
import 'package:tata/shared/common/result/app_result.dart';
import 'package:tata/shared/infrastructure/network/api_client.dart';

import '../support/memory_session_store.dart';

void main() {
  final now = DateTime.utc(2026, 10, 27);
  StoredSession session([SessionRole role = SessionRole.caregiver]) =>
      StoredSession(
        accessToken: 'token-A',
        expiresAt: DateTime.utc(2030),
        owner: SessionOwner(
          'caregiver-A',
          role,
          careLinkId: role == SessionRole.caregiver ? null : 'link-A',
        ),
      );
  final profile = {
    'id': 'adult-A',
    'registeredByCaregiverId': 'caregiver-A',
    'fullName': 'Adult Name',
    'birthDate': '1958-05-03',
  };
  final pending = {
    'id': 'link-A',
    'caregiverId': 'caregiver-A',
    'olderAdultId': 'adult-A',
    'status': 'PENDING',
    'linkingCode': 'TATA-TEST',
    'codeExpiresAt': '2030-01-01T00:00:00Z',
    'consentGranted': false,
    'codeUsedAt': null,
  };
  RemoteCareLinkRepository repository(
    MemorySessionStore store,
    Future<http.Response> Function(http.Request) handler,
  ) {
    final client = ApiClient(
      baseUrl: Uri.parse('https://example.com/'),
      client: MockClient(handler),
    );
    addTearDown(client.close);
    return RemoteCareLinkRepository(
      api: CareLinkApi(client),
      store: store,
      clock: () => now,
    );
  }

  test('caregiver identity is captured for confirmed list, registration and code generation', () async {
    final store = MemorySessionStore(session());
    final repo = repository(store, (request) async {
      expect(request.headers['Authorization'], 'Bearer token-A');
      switch (request.url.path) {
        case '/api/v1/care-links':
          expect(request.url.queryParameters, {'caregiverId': 'caregiver-A'});
          return http.Response('[]', 200);
        case '/api/v1/older-adults':
          expect(jsonDecode(request.body), {
            'caregiverId': 'caregiver-A',
            'fullName': 'Adult Name',
            'birthDate': '1958-05-03',
          });
          return http.Response(jsonEncode(profile), 201);
        case '/api/v1/care-links/linking-codes':
          expect(jsonDecode(request.body), {
            'caregiverId': 'caregiver-A',
            'olderAdultId': 'adult-A',
          });
          return http.Response(jsonEncode(pending), 201);
        default:
          throw StateError('Unexpected request');
      }
    });
    expect(
      await repo.readConfirmed(),
      isA<AppSuccess>().having((r) => r.value, 'empty', isEmpty),
    );
    expect(
      await RegisterOlderAdult(repo, () => now)(
        ' Adult Name ',
        DateTime(1958, 5, 3),
      ),
      isA<AppSuccess>(),
    );
    final code = await GenerateLinkingCode(repo)('adult-A');
    expect(code, isA<AppSuccess>());
    expect(code.toString(), isNot(contains('TATA-TEST')));
    expect(store.current?.owner.role, SessionRole.caregiver);
    expect(store.writes, 0);
  });

  test('anonymous and adult actors cannot call caregiver endpoints', () async {
    var calls = 0;
    for (final credential in [null, session(SessionRole.olderAdult)]) {
      final repo = repository(MemorySessionStore(credential), (_) async {
        calls++;
        return http.Response('[]', 200);
      });
      expect(await repo.readConfirmed(), isA<AppFailure>());
    }
    expect(calls, 0);
  });

  test('foreign profile, normalized impossible date and mismatched linking owner are rejected', () async {
    for (final response in [
      {...profile, 'registeredByCaregiverId': 'other'},
      {...profile, 'birthDate': '1958-02-31'},
    ]) {
      final repo = repository(
        MemorySessionStore(session()),
        (_) async => http.Response(jsonEncode(response), 201),
      );
      expect(
        await repo.registerOlderAdult('Adult Name', DateTime.utc(1958, 5, 3)),
        isA<AppFailure>(),
      );
    }
    for (final response in [
      {...pending, 'caregiverId': 'other'},
      {...pending, 'olderAdultId': 'other'},
      {...pending, 'codeExpiresAt': '2020-01-01T00:00:00Z'},
      {...pending, 'consentGranted': true},
      {...pending, 'accessToken': 'unexpected-adult-token'},
    ]) {
      final repo = repository(
        MemorySessionStore(session()),
        (_) async => http.Response(jsonEncode(response), 201),
      );
      expect(await repo.generateCode('adult-A'), isA<AppFailure>());
    }
  });

  test(
    'duplicate list rows are invalid rather than duplicated family cards',
    () async {
      final entry = {
        'id': 'link-A',
        'olderAdultId': 'adult-A',
        'olderAdultName': 'Adult Name',
        'confirmedAt': '2026-10-20T00:00:00Z',
      };
      final repo = repository(
        MemorySessionStore(session()),
        (_) async => http.Response(jsonEncode([entry, entry]), 200),
      );
      expect(
        await repo.readConfirmed(),
        isA<AppFailure>().having((r) => r.code, 'code', 'INVALID_RESPONSE'),
      );
    },
  );

  test('logout while a request is pending discards the previous caregiver response', () async {
    final store = MemorySessionStore(session());
    final pendingResponse = Completer<http.Response>();
    final started = Completer<void>();
    final repo = repository(store, (_) {
      started.complete();
      return pendingResponse.future;
    });
    final response = repo.readConfirmed();
    await started.future;
    await store.replace(null, expectedGeneration: store.generation);
    pendingResponse.complete(http.Response('[]', 200));
    expect(
      await response,
      isA<AppFailure>().having((r) => r.code, 'code', 'SESSION_CHANGED'),
    );
  });

  test(
    '401 clears only the captured session; 403 does not erase valid access',
    () async {
      for (final status in [401, 403]) {
        final store = MemorySessionStore(session());
        final repo = repository(store, (_) async => http.Response('', status));
        expect(await repo.readConfirmed(), isA<AppFailure>());
        expect(store.current == null, status == 401);
      }
    },
  );

  test(
    'future dates and empty names perform no registration request',
    () async {
      var calls = 0;
      final repo = repository(MemorySessionStore(session()), (_) async {
        calls++;
        return http.Response('', 500);
      });
      expect(
        await RegisterOlderAdult(repo, () => now)('', DateTime(1958)),
        isA<AppFailure>(),
      );
      expect(
        await RegisterOlderAdult(repo, () => now)('Name', DateTime(2030)),
        isA<AppFailure>(),
      );
      expect(calls, 0);
    },
  );
}
