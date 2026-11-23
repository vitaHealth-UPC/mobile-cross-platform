import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tata/features/care_link/application/usecases/accept_care_link.dart';
import 'package:tata/features/care_link/domain/value_objects/care_link_invitation.dart';
import 'package:tata/features/care_link/infrastructure/remote/care_link_api.dart';
import 'package:tata/features/care_link/infrastructure/repositories/remote_care_link_consent.dart';
import 'package:tata/shared/application/session/session_owner.dart';
import 'package:tata/shared/application/session/stored_session.dart';
import 'package:tata/shared/common/result/app_result.dart';
import 'package:tata/shared/infrastructure/network/api_client.dart';

import '../support/memory_session_store.dart';

void main() {
  final now = DateTime.utc(2026, 10, 27);
  final invitation = CareLinkInvitation(
    caregiverId: 'caregiver-A',
    code: 'tata-1234',
  );
  Map<String, Object?> receipt({bool? decision, bool credential = true}) => {
    'id': 'link-A',
    'caregiverId': 'caregiver-A',
    'olderAdultId': 'adult-A',
    'status': decision == null
        ? 'AWAITING_CONSENT'
        : decision
        ? 'CONFIRMED'
        : 'REVOKED',
    'consentGranted': decision == true,
    'codeUsedAt': '2026-10-27T00:00:00Z',
    'consentRecordedAt': decision == null ? null : '2026-10-27T00:01:00Z',
    'confirmedAt': decision == true ? '2026-10-27T00:01:00Z' : null,
    'accessToken': credential && decision != false
        ? (decision == true ? 'adult-token' : 'setup-token')
        : null,
    'expiresAt': credential && decision != false
        ? '2030-01-01T00:00:00Z'
        : null,
  };
  StoredSession setup() => StoredSession(
    accessToken: 'setup-token',
    expiresAt: DateTime.utc(2030),
    owner: SessionOwner('adult-A', SessionRole.linkSetup, careLinkId: 'link-A'),
  );
  RemoteCareLinkConsent repository(
    MemorySessionStore store,
    Future<http.Response> Function(http.Request) handler,
  ) {
    final client = ApiClient(
      baseUrl: Uri.parse('https://example.com/'),
      client: MockClient(handler),
    );
    addTearDown(client.close);
    return RemoteCareLinkConsent(
      api: CareLinkApi(client),
      store: store,
      clock: () => now,
    );
  }

  test(
    'invitation is versioned, bounded and preserves both acceptance fields',
    () {
      final copy = CareLinkInvitation.fromText(invitation.encode());
      expect(copy.caregiverId, 'caregiver-A');
      expect(copy.code, 'TATA-1234');
      expect(copy.toString(), isNot(contains(copy.code)));
      for (final invalid in [
        'TATA-1234',
        'https://example.com/invitation',
        'tata-link:v2:any',
        'tata-link:v1:!',
        'x' * 2049,
      ]) {
        expect(
          () => CareLinkInvitation.fromText(invalid),
          throwsFormatException,
        );
      }
    },
  );

  test('acceptance grants only restricted scope; approval replaces it with scoped adult access', () async {
    final store = MemorySessionStore();
    final repo = repository(store, (request) async {
      if (request.url.path.endsWith('/acceptances')) {
        expect(request.headers.containsKey('Authorization'), false);
        expect(jsonDecode(request.body), {
          'caregiverId': 'caregiver-A',
          'code': 'TATA-1234',
        });
        return http.Response(jsonEncode(receipt()), 200);
      }
      expect(request.headers['Authorization'], 'Bearer setup-token');
      expect(
        request.url.path,
        anyOf('/api/v1/care-links/link-A', '/api/v1/care-links/link-A/consent'),
      );
      return http.Response(
        jsonEncode(
          receipt(
            decision: request.method == 'POST' ? true : null,
            credential: request.method == 'POST',
          ),
        ),
        200,
      );
    });
    expect(await AcceptCareLink(repo)(invitation.encode()), isA<AppSuccess>());
    expect(store.current?.owner.role, SessionRole.linkSetup);
    expect(store.current?.owner.careLinkId, 'link-A');
    expect(await repo.pending(), isA<AppSuccess>());
    expect(await repo.decide(true), isA<AppSuccess>());
    expect(store.current?.owner.role, SessionRole.olderAdult);
    expect(store.current?.owner.careLinkId, 'link-A');
    expect(store.current?.accessToken, 'adult-token');
  });

  test(
    'rejection requires matching revoked receipt and clears restricted access',
    () async {
      final store = MemorySessionStore(setup());
      final repo = repository(store, (request) async {
        expect(jsonDecode(request.body), {'accepted': false});
        return http.Response(jsonEncode(receipt(decision: false)), 200);
      });
      expect(await repo.decide(false), isA<AppSuccess>());
      expect(store.current, isNull);
    },
  );

  test('caregiver and full adult sessions cannot be replaced by anonymous acceptance or decide', () async {
    var calls = 0;
    for (final owner in [
      SessionOwner('caregiver-A', SessionRole.caregiver),
      SessionOwner('adult-A', SessionRole.olderAdult, careLinkId: 'link-A'),
    ]) {
      final store = MemorySessionStore(
        StoredSession(
          accessToken: 'existing-token',
          expiresAt: DateTime.utc(2030),
          owner: owner,
        ),
      );
      final repo = repository(store, (_) async {
        calls++;
        return http.Response('{}', 200);
      });
      expect(await repo.accept(invitation), isA<AppFailure>());
      expect(await repo.decide(true), isA<AppFailure>());
      expect(store.current?.accessToken, 'existing-token');
    }
    expect(calls, 0);
  });

  test('foreign relationship, premature approval and malformed rejection never grant access', () async {
    for (final body in [
      {...receipt(decision: true), 'id': 'other-link'},
      {...receipt(decision: true), 'olderAdultId': 'other-adult'},
      receipt(),
      {...receipt(decision: true), 'expiresAt': '2020-01-01T00:00:00Z'},
    ]) {
      final store = MemorySessionStore(setup());
      final repo = repository(
        store,
        (_) async => http.Response(jsonEncode(body), 200),
      );
      expect(await repo.decide(true), isA<AppFailure>());
      expect(store.current?.owner.role, SessionRole.linkSetup);
    }
    final store = MemorySessionStore(setup());
    final repo = repository(
      store,
      (_) async => http.Response(
        jsonEncode({...receipt(decision: false), 'accessToken': 'unexpected'}),
        200,
      ),
    );
    expect(await repo.decide(false), isA<AppFailure>());
    expect(store.current?.owner.role, SessionRole.linkSetup);
  });

  test(
    'late acceptance cannot restore a session superseded by logout',
    () async {
      final store = MemorySessionStore();
      final response = Completer<http.Response>();
      final started = Completer<void>();
      final repo = repository(store, (_) {
        started.complete();
        return response.future;
      });
      final acceptance = repo.accept(invitation);
      await started.future;
      await store.replace(null, expectedGeneration: store.generation);
      response.complete(http.Response(jsonEncode(receipt()), 200));
      expect(
        await acceptance,
        isA<AppFailure>().having((r) => r.code, 'code', 'SESSION_CHANGED'),
      );
      expect(store.current, isNull);
    },
  );

  test('withdrawal uses the adult scope and distinguishes acknowledgment, revocation and outage', () async {
    for (final status in [204, 401, 503]) {
      final store = MemorySessionStore(
        StoredSession(
          accessToken: 'adult-token',
          expiresAt: DateTime.utc(2030),
          owner: SessionOwner(
            'adult-A',
            SessionRole.olderAdult,
            careLinkId: 'link-A',
          ),
        ),
      );
      final repo = repository(store, (request) async {
        expect(request.method, 'DELETE');
        expect(request.url.path, '/api/v1/care-links/link-A/consent');
        expect(request.headers['Authorization'], 'Bearer adult-token');
        expect(request.body, isEmpty);
        return http.Response('', status);
      });
      final result = await repo.withdraw();
      expect(result is AppSuccess<void>, status == 204);
      expect(store.current == null, status == 204 || status == 401);
    }
  });

  test(
    'caregiver and restricted sessions cannot withdraw confirmed adult consent',
    () async {
      var calls = 0;
      for (final owner in [
        SessionOwner('caregiver-A', SessionRole.caregiver),
        SessionOwner('adult-A', SessionRole.linkSetup, careLinkId: 'link-A'),
      ]) {
        final store = MemorySessionStore(
          StoredSession(
            accessToken: 'token',
            expiresAt: DateTime.utc(2030),
            owner: owner,
          ),
        );
        final repo = repository(store, (_) async {
          calls++;
          return http.Response('', 204);
        });
        expect(
          await repo.withdraw(),
          isA<AppFailure>().having((r) => r.code, 'code', 'ACCESS_DENIED'),
        );
        expect(store.current?.owner, owner);
      }
      expect(calls, 0);
    },
  );

  test(
    'late withdrawal acknowledgment cannot erase a replacement actor',
    () async {
      final store = MemorySessionStore(
        StoredSession(
          accessToken: 'adult-token',
          expiresAt: DateTime.utc(2030),
          owner: SessionOwner(
            'adult-A',
            SessionRole.olderAdult,
            careLinkId: 'link-A',
          ),
        ),
      );
      final response = Completer<http.Response>();
      final started = Completer<void>();
      final repo = repository(store, (_) {
        started.complete();
        return response.future;
      });
      final withdrawal = repo.withdraw();
      await started.future;
      await store.replace(
        StoredSession(
          accessToken: 'replacement',
          expiresAt: DateTime.utc(2030),
          owner: SessionOwner('caregiver-B', SessionRole.caregiver),
        ),
        expectedGeneration: store.generation,
      );
      response.complete(http.Response('', 204));
      expect(
        await withdrawal,
        isA<AppFailure>().having((r) => r.code, 'code', 'SESSION_CHANGED'),
      );
      expect(store.current?.owner.id, 'caregiver-B');
    },
  );
}
