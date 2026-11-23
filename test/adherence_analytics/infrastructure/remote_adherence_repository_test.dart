import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tata/features/adherence_analytics/application/readmodels/adherence_recommendation.dart';
import 'package:tata/features/adherence_analytics/application/readmodels/adherence_summary.dart';
import 'package:tata/features/adherence_analytics/infrastructure/remote/analytics_api.dart';
import 'package:tata/features/adherence_analytics/infrastructure/repositories/remote_adherence_repository.dart';
import 'package:tata/shared/application/session/session_owner.dart';
import 'package:tata/shared/application/session/stored_session.dart';
import 'package:tata/shared/common/result/app_result.dart';
import 'package:tata/shared/infrastructure/network/api_client.dart';

import '../../support/memory_session_store.dart';
import 'adherence_mapper_test.dart' show insightJson, summaryJson;

/// UTF-8 like the backend; a plain String body would be latin1-encoded.
http.Response _json(Object? body, int status) => http.Response.bytes(
  utf8.encode(jsonEncode(body)),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

void main() {
  StoredSession session(
    SessionRole role, {
    String id = 'adult-A',
    String token = 'token-1',
  }) => StoredSession(
    accessToken: token,
    expiresAt: DateTime.utc(2030),
    owner: SessionOwner(
      id,
      role,
      careLinkId: role == SessionRole.caregiver ? null : 'link-A',
    ),
  );

  RemoteAdherenceRepository repository(
    MemorySessionStore store,
    Future<http.Response> Function(http.Request) handler,
  ) {
    final client = ApiClient(
      baseUrl: Uri.parse('https://example.com/'),
      client: MockClient(handler),
    );
    addTearDown(client.close);
    return RemoteAdherenceRepository(
      api: AnalyticsApi(client),
      store: store,
      zoneId: 'America/Lima',
    );
  }

  test('treatment summary uses a dedicated scoped route and never falls back to the adult summary', () async {
    var calls = 0;
    final repo = repository(
      MemorySessionStore(session(SessionRole.caregiver, id: 'caregiver-1')),
      (request) async {
        calls++;
        expect(
          request.url.path,
          '/api/v1/older-adults/adult-B/adherence/treatments/treatment-1/summary',
        );
        expect(request.url.queryParameters, {
          'days': '7',
          'zone': 'America/Lima',
        });
        expect(request.headers['Authorization'], 'Bearer token-1');
        return _json({}, 404);
      },
    );
    final result = await repo.summary('adult-B', 7, treatmentId: 'treatment-1');
    expect(result, isA<AppFailure>());
    expect(calls, 1);
  });

  test(
    'a caregiver reads the summary of a linked adult with the zone',
    () async {
      final repo = repository(
        MemorySessionStore(
          session(SessionRole.caregiver, id: 'caregiver-1', token: 'cg-token'),
        ),
        (request) async {
          expect(request.method, 'GET');
          expect(
            request.url.path,
            '/api/v1/older-adults/adult-B/adherence/summary',
          );
          expect(request.url.queryParameters, {
            'days': '30',
            'zone': 'America/Lima',
          });
          expect(request.headers['Authorization'], 'Bearer cg-token');
          return _json(summaryJson(), 200);
        },
      );

      final result = await repo.summary('adult-B', 30);

      final summary = (result as AppSuccess<AdherenceSummary?>).value;
      expect(summary?.adherencePercent, 92);
      expect(summary?.pattern?.timeBand, AdherenceTimeBand.evening);
    },
  );

  test('the insight uses the singular insight path', () async {
    final repo = repository(
      MemorySessionStore(session(SessionRole.caregiver, id: 'caregiver-1')),
      (request) async {
        expect(
          request.url.path,
          '/api/v1/older-adults/adult-B/adherence/insight',
        );
        return _json(insightJson(), 200);
      },
    );

    final result = await repo.insight('adult-B', 30);

    final insight = (result as AppSuccess<AdherenceInsight?>).value;
    expect(insight?.recommendations, hasLength(3));
  });

  test('204 is a legitimate empty result for both readers', () async {
    final repo = repository(
      MemorySessionStore(session(SessionRole.caregiver, id: 'caregiver-1')),
      (_) async => http.Response('', 204),
    );

    final summary = await repo.summary('adult-B', 7);
    final insight = await repo.insight('adult-B', 30);

    expect((summary as AppSuccess<AdherenceSummary?>).value, isNull);
    expect((insight as AppSuccess<AdherenceInsight?>).value, isNull);
  });

  test('an adult reads their own evidence but never another adult', () async {
    var calls = 0;
    final repo = repository(
      MemorySessionStore(session(SessionRole.olderAdult)),
      (_) async {
        calls++;
        return _json(summaryJson(), 200);
      },
    );

    final own = await repo.summary('adult-A', 30);
    final other = await repo.summary('adult-B', 30);

    expect(own, isA<AppSuccess<AdherenceSummary?>>());
    expect((other as AppFailure).code, 'ACCESS_DENIED');
    expect(calls, 1);
  });

  test('setup sessions and missing sessions read nothing', () async {
    var calls = 0;
    Future<http.Response> handler(http.Request _) async {
      calls++;
      return _json(summaryJson(), 200);
    }

    final setup = await repository(
      MemorySessionStore(session(SessionRole.linkSetup)),
      handler,
    ).summary('adult-A', 30);
    final none = await repository(
      MemorySessionStore(),
      handler,
    ).summary('adult-A', 30);

    expect((setup as AppFailure).code, 'ACCESS_DENIED');
    expect((none as AppFailure).code, 'AUTHENTICATION_REQUIRED');
    expect(calls, 0);
  });

  test('401 clears the rejected credential and 403 denies access', () async {
    final store = MemorySessionStore(
      session(SessionRole.caregiver, id: 'caregiver-1'),
    );
    final unauthorized = await repository(
      store,
      (_) async => http.Response('', 401),
    ).summary('adult-B', 30);

    expect((unauthorized as AppFailure).code, 'AUTHENTICATION_REQUIRED');
    expect(store.current, isNull);

    final forbidden = await repository(
      MemorySessionStore(session(SessionRole.caregiver, id: 'caregiver-1')),
      (_) async => http.Response('', 403),
    ).insight('adult-B', 30);

    expect((forbidden as AppFailure).code, 'ACCESS_DENIED');
  });

  test('other statuses map to stable codes', () async {
    for (final (status, code) in [
      (400, 'INVALID_REQUEST'),
      (429, 'RATE_LIMITED'),
      (500, 'REQUEST_FAILED'),
      (503, 'REQUEST_FAILED'),
    ]) {
      final result = await repository(
        MemorySessionStore(session(SessionRole.caregiver, id: 'caregiver-1')),
        (_) async => _json({'title': 'ERROR'}, status),
      ).summary('adult-B', 30);

      expect((result as AppFailure).code, code, reason: '$status');
    }
  });

  test(
    'a broken or contradictory success body is an invalid response',
    () async {
      for (final body in <Object?>[
        summaryJson(overrides: {'periodDays': 7}),
        summaryJson(overrides: {'adherencePercent': 400}),
        {'unexpected': true},
      ]) {
        final result = await repository(
          MemorySessionStore(session(SessionRole.caregiver, id: 'caregiver-1')),
          (_) async => _json(body, 200),
        ).summary('adult-B', 30);

        expect((result as AppFailure).code, 'INVALID_RESPONSE');
      }
    },
  );

  test('transport failures keep their stable code', () async {
    final result = await repository(
      MemorySessionStore(session(SessionRole.caregiver, id: 'caregiver-1')),
      (_) async => throw http.ClientException('offline'),
    ).summary('adult-B', 30);

    expect((result as AppFailure).code, 'NETWORK_UNAVAILABLE');
  });

  test(
    'a response that arrives after the session changed is discarded',
    () async {
      final store = MemorySessionStore(
        session(SessionRole.caregiver, id: 'caregiver-1'),
      );
      final repo = repository(store, (_) async {
        await store.replace(
          session(SessionRole.caregiver, id: 'caregiver-2', token: 'token-2'),
          expectedGeneration: store.generation,
        );
        return _json(summaryJson(), 200);
      });

      final result = await repo.summary('adult-B', 30);

      expect((result as AppFailure).code, 'SESSION_CHANGED');
    },
  );
}
