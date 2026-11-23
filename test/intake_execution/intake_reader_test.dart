import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tata/features/intake_execution/application/ports/intake_reader.dart';
import 'package:tata/features/intake_execution/application/readmodels/daily_progress.dart';
import 'package:tata/features/intake_execution/application/usecases/get_daily_progress.dart';
import 'package:tata/features/intake_execution/application/usecases/get_next_intake.dart';
import 'package:tata/features/intake_execution/domain/entities/intake.dart';
import 'package:tata/features/intake_execution/infrastructure/remote/intake_api.dart';
import 'package:tata/features/intake_execution/infrastructure/repositories/remote_intake_reader.dart';
import 'package:tata/shared/application/session/session_owner.dart';
import 'package:tata/shared/application/session/stored_session.dart';
import 'package:tata/shared/common/result/app_result.dart';
import 'package:tata/shared/infrastructure/network/api_client.dart';

import '../support/memory_session_store.dart';

Map<String, Object?> intakeJson({
  String id = 'intake-1',
  String adult = 'adult-A',
  String status = 'PENDING',
  String scheduledAt = '2026-11-03T13:00:00Z',
}) => {
  'id': id,
  'treatmentId': 'treatment-1',
  'medicationId': 'medication-1',
  'olderAdultId': adult,
  'medicationName': 'Losartán 50 mg',
  'dose': '1 tableta',
  'instructions': null,
  'scheduledAt': scheduledAt,
  'status': status,
  'confirmedAt': status == 'CONFIRMED' || status == 'LATE' ? scheduledAt : null,
  'confirmationChannel': null,
  'alreadyConfirmed': false,
};

/// UTF-8 like the backend; a plain String body would be latin1-encoded.
http.Response _json(Object? body, int status) => http.Response.bytes(
  utf8.encode(jsonEncode(body)),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

void main() {
  StoredSession session(SessionRole role) => StoredSession(
    accessToken: 'adult-token',
    expiresAt: DateTime.utc(2030),
    owner: SessionOwner(
      'adult-A',
      role,
      careLinkId: role == SessionRole.caregiver ? null : 'link-A',
    ),
  );

  RemoteIntakeReader reader(
    MemorySessionStore store,
    Future<http.Response> Function(http.Request) handler,
  ) {
    final client = ApiClient(
      baseUrl: Uri.parse('https://example.com/'),
      client: MockClient(handler),
    );
    addTearDown(client.close);
    return RemoteIntakeReader(api: IntakeApi(client), store: store);
  }

  test('next intake is read for the session adult with its bearer', () async {
    final repo = reader(MemorySessionStore(session(SessionRole.olderAdult)), (
      request,
    ) async {
      expect(request.url.path, '/api/v1/older-adults/adult-A/intakes/next');
      expect(request.headers['Authorization'], 'Bearer adult-token');
      return _json(intakeJson(), 200);
    });
    final result = await GetNextIntake(repo)();
    final intake = (result as AppSuccess<Intake?>).value;
    expect(intake?.medicationName, 'Losartán 50 mg');
    expect(intake?.scheduledAt, DateTime.utc(2026, 11, 3, 13));
    expect(intake?.status, IntakeStatus.pending);
  });

  test('204 is a legitimate empty next intake', () async {
    final repo = reader(
      MemorySessionStore(session(SessionRole.olderAdult)),
      (_) async => http.Response('', 204),
    );
    final result = await GetNextIntake(repo)();
    expect((result as AppSuccess<Intake?>).value, isNull);
  });

  test('evidence of another adult or a local timestamp is rejected', () async {
    for (final body in [
      intakeJson(adult: 'adult-B'),
      intakeJson(scheduledAt: '2026-11-03T13:00:00'),
      intakeJson(status: 'UNKNOWN'),
    ]) {
      final repo = reader(
        MemorySessionStore(session(SessionRole.olderAdult)),
        (_) async => _json(body, 200),
      );
      final result = await GetNextIntake(repo)();
      expect((result as AppFailure).code, 'INVALID_RESPONSE');
    }
  });

  test('only full adult sessions read clinical data', () async {
    var calls = 0;
    for (final role in [SessionRole.linkSetup, SessionRole.caregiver]) {
      final repo = reader(MemorySessionStore(session(role)), (_) async {
        calls++;
        return http.Response('', 204);
      });
      final result = await GetNextIntake(repo)();
      expect((result as AppFailure).code, 'ACCESS_DENIED');
    }
    expect(calls, 0);
  });

  test('a rejected bearer clears the stored session', () async {
    final store = MemorySessionStore(session(SessionRole.olderAdult));
    final repo = reader(store, (_) async => http.Response('', 401));
    final result = await GetNextIntake(repo)();
    expect((result as AppFailure).code, 'AUTHENTICATION_REQUIRED');
    expect(store.current, isNull);
  });

  test(
    'daily progress asks for the local day and counts taken intakes',
    () async {
      final now = DateTime(2026, 11, 3, 9, 30);
      final from = DateTime(2026, 11, 3).toUtc();
      final to = DateTime(2026, 11, 4).toUtc();
      final repo = reader(MemorySessionStore(session(SessionRole.olderAdult)), (
        request,
      ) async {
        expect(request.url.path, '/api/v1/older-adults/adult-A/intakes/agenda');
        expect(DateTime.parse(request.url.queryParameters['from']!), from);
        expect(DateTime.parse(request.url.queryParameters['to']!), to);
        String at(int hour) =>
            DateTime(2026, 11, 3, hour).toUtc().toIso8601String();
        return _json([
          intakeJson(id: 'a', status: 'CONFIRMED', scheduledAt: at(8)),
          intakeJson(id: 'a', status: 'CONFIRMED', scheduledAt: at(8)),
          intakeJson(id: 'b', status: 'LATE', scheduledAt: at(12)),
          intakeJson(id: 'c', status: 'OMITTED', scheduledAt: at(14)),
          intakeJson(id: 'd', scheduledAt: at(20)),
        ], 200);
      });
      final result = await GetDailyProgress(repo, () => now)();
      final progress = (result as AppSuccess<DailyProgress>).value;
      expect(progress.taken, 2);
      expect(progress.total, 4);
    },
  );

  test('daily progress forwards reader failures', () async {
    final result = await GetDailyProgress(
      _FailingReader(),
      () => DateTime(2026, 11, 3),
    )();
    expect((result as AppFailure).code, 'NETWORK_UNAVAILABLE');
  });
}

final class _FailingReader implements IntakeReader {
  @override
  Future<AppResult<List<Intake>>> agenda(DateTime from, DateTime to) async =>
      const AppFailure('NETWORK_UNAVAILABLE');

  @override
  Future<AppResult<Intake?>> next() async =>
      const AppFailure('NETWORK_UNAVAILABLE');

  @override
  Future<AppResult<Intake>> detail(String intakeId) async =>
      const AppFailure('NETWORK_UNAVAILABLE');
}
