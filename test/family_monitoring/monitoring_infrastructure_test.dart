import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tata/features/family_monitoring/domain/value_objects/alert_status.dart';
import 'package:tata/features/family_monitoring/domain/value_objects/contact_channel.dart';
import 'package:tata/features/family_monitoring/domain/value_objects/note_values.dart';
import 'package:tata/features/family_monitoring/infrastructure/mappers/monitoring_mapper.dart';
import 'package:tata/features/family_monitoring/infrastructure/remote/family_monitoring_api.dart';
import 'package:tata/features/family_monitoring/infrastructure/repositories/remote_alerts_repository.dart';
import 'package:tata/features/family_monitoring/infrastructure/repositories/remote_contact_repository.dart';
import 'package:tata/features/family_monitoring/infrastructure/repositories/remote_family_monitoring_repository.dart';
import 'package:tata/features/family_monitoring/infrastructure/repositories/remote_notes_repositories.dart';
import 'package:tata/shared/application/session/session_owner.dart';
import 'package:tata/shared/application/session/stored_session.dart';
import 'package:tata/shared/common/result/app_result.dart';
import 'package:tata/shared/infrastructure/network/api_client.dart';

import '../support/memory_session_store.dart';

Map<String, Object?> alertJson({
  int id = 7,
  String status = 'OPEN',
  String? closedAt,
}) => {
  'id': id,
  'intakeId': 'intake-1',
  'medicationName': 'Losartán',
  'scheduledAt': '2026-11-13T08:00:00Z',
  'reason': 'No respondió',
  'status': status,
  'openedAt': '2026-11-13T08:30:00Z',
  'closedAt': ?closedAt,
};

void main() {
  StoredSession session({
    String token = 'token-c',
    SessionRole role = SessionRole.caregiver,
    String id = 'caregiver-1',
  }) => StoredSession(
    accessToken: token,
    expiresAt: DateTime.utc(2030),
    owner: SessionOwner(
      id,
      role,
      careLinkId: role == SessionRole.caregiver ? null : 'link-1',
    ),
  );

  FamilyMonitoringApi apiFor(
    Future<http.Response> Function(http.Request) handler,
  ) {
    final client = ApiClient(
      baseUrl: Uri.parse('https://example.com/'),
      client: MockClient(handler),
    );
    addTearDown(client.close);
    return FamilyMonitoringApi(client);
  }

  http.Response json(Object body, [int status = 200]) => http.Response(
    jsonEncode(body),
    status,
    headers: {'content-type': 'application/json'},
  );

  group('mapper', () {
    test('rejects what it cannot read instead of defaulting', () {
      expect(
        () => MonitoringMapper.alert(alertJson(status: 'SNOOZED')),
        throwsFormatException,
      );
      final naive = alertJson()..['scheduledAt'] = '2026-11-13T08:00:00';
      expect(() => MonitoringMapper.alert(naive), throwsFormatException);
      expect(
        () => MonitoringMapper.person({
          'id': 'a',
          'fullName': 'Rosa',
          'birthDate': '2999-01-01',
        }),
        throwsFormatException,
      );
      expect(
        () => MonitoringMapper.inventory({
          'medicationId': 'm',
          'remainingStock': -1,
          'lowStock': false,
        }),
        throwsFormatException,
      );
    });

    test('reads a closed alert and keeps the closing instant', () {
      final alert = MonitoringMapper.alert(
        alertJson(status: 'CLOSED', closedAt: '2026-11-13T09:00:00Z'),
      );
      expect(alert.status, AlertStatus.closed);
      expect(alert.closedAt, DateTime.utc(2026, 11, 13, 9));
    });

    test('an alert marked closed without closing instant is invalid', () {
      expect(
        () => MonitoringMapper.alert(alertJson(status: 'CLOSED')),
        throwsArgumentError,
      );
    });

    test('repeated ids are rejected, not merged', () {
      expect(
        () => MonitoringMapper.followUpNotes([
          {
            'id': 1,
            'text': 'a',
            'recordedAt': '2026-11-13T08:00:00Z',
            'familiarId': 'c',
          },
          {
            'id': 1,
            'text': 'b',
            'recordedAt': '2026-11-13T08:00:00Z',
            'familiarId': 'c',
          },
        ]),
        throwsFormatException,
      );
    });
  });

  group('alerts repository', () {
    test('asks with the caregiver of the session and its bearer', () async {
      late http.Request seen;
      final repository = RemoteAlertsRepository(
        api: apiFor((request) async {
          seen = request;
          return json(alertJson());
        }),
        store: MemorySessionStore(session()),
      );
      final result = await repository.alert('adult-1', 7);
      expect(result, isA<AppSuccess>());
      expect(seen.url.path, '/api/v1/older-adults/adult-1/alerts/7');
      expect(seen.url.queryParameters['caregiverId'], 'caregiver-1');
      expect(seen.headers['Authorization'], 'Bearer token-c');
    });

    test('an older adult session cannot read caregiver alerts', () async {
      var calls = 0;
      final repository = RemoteAlertsRepository(
        api: apiFor((request) async {
          calls++;
          return json(alertJson());
        }),
        store: MemorySessionStore(
          session(role: SessionRole.olderAdult, id: 'adult-1'),
        ),
      );
      final result = await repository.alert('adult-1', 7);
      expect((result as AppFailure).code, 'ACCESS_DENIED');
      expect(calls, 0);
    });

    test(
      'updates the status with only the target and maps conflicts',
      () async {
        late http.Request seen;
        var answer = 200;
        final repository = RemoteAlertsRepository(
          api: apiFor((request) async {
            seen = request;
            return answer == 200
                ? json(alertJson(status: 'ATTENDED'))
                : http.Response('', answer);
          }),
          store: MemorySessionStore(session()),
        );
        final ok = await repository.updateStatus(
          'adult-1',
          7,
          AlertStatus.attended,
        );
        expect((ok as AppSuccess).value.status, AlertStatus.attended);
        expect(seen.method, 'PUT');
        expect(seen.url.path, '/api/v1/older-adults/adult-1/alerts/7/status');
        expect(jsonDecode(seen.body), {'status': 'ATTENDED'});

        answer = 409;
        final conflict = await repository.updateStatus(
          'adult-1',
          7,
          AlertStatus.closed,
        );
        expect((conflict as AppFailure).code, 'ALERT_STATUS_CONFLICT');
        answer = 404;
        final missing = await repository.alert('adult-1', 7);
        expect((missing as AppFailure).code, 'NOT_FOUND');
      },
    );

    test('an unreadable answer is an invalid response', () async {
      final repository = RemoteAlertsRepository(
        api: apiFor((request) async => json({'id': 7})),
        store: MemorySessionStore(session()),
      );
      final result = await repository.alert('adult-1', 7);
      expect((result as AppFailure).code, 'INVALID_RESPONSE');
    });
  });

  group('notes repositories', () {
    test('registers a note with the author in the body', () async {
      late http.Request seen;
      final repository = RemoteNotesRepository(
        api: apiFor((request) async {
          seen = request;
          return json({
            'id': 3,
            'text': 'Llamé a Rosa',
            'recordedAt': '2026-11-13T10:00:00Z',
            'familiarId': 'caregiver-1',
          }, 201);
        }),
        store: MemorySessionStore(session()),
      );
      final result = await repository.register('adult-1', 'Llamé a Rosa');
      expect((result as AppSuccess).value.id, 3);
      expect(seen.method, 'POST');
      expect(seen.url.queryParameters, isEmpty);
      expect(jsonDecode(seen.body), {
        'familiarId': 'caregiver-1',
        'text': 'Llamé a Rosa',
      });
    });

    test(
      'personal notes use the adult session and the own-notes path',
      () async {
        late http.Request seen;
        final repository = RemotePersonalNotesRepository(
          api: apiFor((request) async {
            seen = request;
            return json([
              {
                'id': 1,
                'title': 'Agua',
                'text': 'Tomar agua',
                'category': 'ROUTINE',
                'recordedAt': '2026-11-13T07:00:00Z',
              },
            ]);
          }),
          store: MemorySessionStore(
            session(role: SessionRole.olderAdult, id: 'adult-1'),
          ),
        );
        final result = await repository.list();
        expect(seen.url.path, '/api/v1/me/notes');
        expect(
          (result as AppSuccess).value.single.category,
          PersonalNoteCategory.routine,
        );
      },
    );

    test('a caregiver cannot read the adult personal notes', () async {
      final repository = RemotePersonalNotesRepository(
        api: apiFor((request) async => json([])),
        store: MemorySessionStore(session()),
      );
      expect(((await repository.list()) as AppFailure).code, 'ACCESS_DENIED');
    });
  });

  group('contact repository', () {
    test('reads the channel and rejects an unknown type', () async {
      var body = <String, Object?>{'type': 'WHATSAPP', 'value': '+51 999 888'};
      final repository = RemoteContactRepository(
        api: apiFor((request) async => json(body)),
        store: MemorySessionStore(session()),
      );
      final ok = await repository.contactChannel('adult-1');
      final channel = (ok as AppSuccess<ContactChannel>).value;
      expect(channel.type, ContactChannelType.whatsapp);
      expect(channel.digits, '51999888');
      body = {'type': 'FAX', 'value': '1'};
      final bad = await repository.contactChannel('adult-1');
      expect((bad as AppFailure).code, 'INVALID_RESPONSE');
    });
  });

  group('family summary repository', () {
    http.Response route(http.Request request) {
      final path = request.url.path;
      if (path.endsWith('/status')) {
        return json({
          'weeklyAdherence': {'confirmedIntakes': 5, 'totalIntakes': 7},
          'openAlerts': [alertJson()],
        });
      }
      if (path.endsWith('/intakes/agenda')) {
        return json([
          {
            'id': 'i1',
            'medicationId': 'm1',
            'medicationName': 'Losartán',
            'dose': '50 mg',
            'scheduledAt': '2026-11-13T12:00:00Z',
            'status': 'CONFIRMED',
          },
          {
            'id': 'i2',
            'medicationId': 'm2',
            'medicationName': 'Metformina',
            'dose': '850 mg',
            'scheduledAt': '2026-11-13T14:00:00Z',
            'status': 'PENDING',
          },
        ]);
      }
      if (path.endsWith('/intakes/next')) return http.Response('', 204);
      if (path.contains('/inventories/')) {
        return json({
          'medicationId': path.split('/').last,
          'remainingStock': 2,
          'lowStock': path.endsWith('/m2'),
        });
      }
      return http.Response('', 404);
    }

    test(
      'assembles weekly, today, stock and alerts of the caregiver',
      () async {
        final repository = RemoteFamilyMonitoringRepository(
          api: apiFor((request) async => route(request)),
          store: MemorySessionStore(session()),
        );
        final result = await repository.summary(
          'adult-1',
          'Rosa Vargas',
          DateTime(2026, 11, 13),
        );
        expect(
          result,
          isA<AppSuccess<dynamic>>(),
          reason: result is AppFailure ? (result as AppFailure).code : '',
        );
        final summary = (result as AppSuccess).value;
        expect(summary.weekly.confirmed, 5);
        expect(summary.weekly.total, 7);
        expect(summary.today.confirmed, 1);
        expect(summary.today.total, 2);
        expect(summary.nextDose, isNull);
        expect(summary.openAlerts.single.id, 7);
        expect(summary.inventoryAvailable, isTrue);
        expect(summary.stockAttention.single.remaining, 2);
      },
    );

    test('a failing inventory only hides the stock card', () async {
      final repository = RemoteFamilyMonitoringRepository(
        api: apiFor((request) async {
          if (request.url.path.contains('/inventories/')) {
            return http.Response('', 500);
          }
          return route(request);
        }),
        store: MemorySessionStore(session()),
      );
      final result = await repository.summary(
        'adult-1',
        'Rosa Vargas',
        DateTime(2026, 11, 13),
      );
      final summary = (result as AppSuccess).value;
      expect(summary.inventoryAvailable, isFalse);
      expect(summary.weekly.total, 7);
    });

    test('lost access discards the whole summary', () async {
      final repository = RemoteFamilyMonitoringRepository(
        api: apiFor((request) async {
          if (request.url.path.endsWith('/intakes/agenda')) {
            return http.Response('', 403);
          }
          return route(request);
        }),
        store: MemorySessionStore(session()),
      );
      final result = await repository.summary(
        'adult-1',
        'Rosa Vargas',
        DateTime(2026, 11, 13),
      );
      expect((result as AppFailure).code, 'ACCESS_DENIED');
    });
  });
}
