import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tata/features/intake_execution/application/readmodels/agenda_week.dart';
import 'package:tata/features/intake_execution/application/readmodels/confirmation_receipt.dart';
import 'package:tata/features/intake_execution/application/usecases/confirm_intake.dart';
import 'package:tata/features/intake_execution/application/usecases/get_intake_detail.dart';
import 'package:tata/features/intake_execution/domain/entities/intake.dart';
import 'package:tata/features/intake_execution/infrastructure/mappers/intake_mapper.dart';
import 'package:tata/features/intake_execution/infrastructure/remote/intake_api.dart';
import 'package:tata/features/intake_execution/infrastructure/repositories/remote_intake_confirmation.dart';
import 'package:tata/features/intake_execution/infrastructure/repositories/remote_intake_reader.dart';
import 'package:tata/shared/application/session/session_owner.dart';
import 'package:tata/shared/application/session/stored_session.dart';
import 'package:tata/shared/common/result/app_result.dart';
import 'package:tata/shared/infrastructure/network/api_client.dart';

import '../support/memory_session_store.dart';

Map<String, Object?> evidence({
  String id = 'intake-1',
  String adult = 'adult-A',
  String status = 'CONFIRMED',
  bool alreadyConfirmed = false,
}) {
  final taken = status == 'CONFIRMED' || status == 'LATE';
  return {
    'id': id,
    'treatmentId': 'treatment-1',
    'medicationId': 'medication-1',
    'olderAdultId': adult,
    'medicationName': 'Losartán',
    'dose': '1 tableta',
    'instructions': 'Con agua',
    'scheduledAt': '2026-11-03T13:00:00Z',
    'status': status,
    'confirmedAt': taken ? '2026-11-03T12:58:00Z' : null,
    'confirmationChannel': taken ? 'TOUCH' : null,
    'alreadyConfirmed': alreadyConfirmed,
  };
}

http.Response _json(Object? body, int status) => http.Response.bytes(
  utf8.encode(jsonEncode(body)),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

void main() {
  StoredSession session([SessionRole role = SessionRole.olderAdult]) =>
      StoredSession(
        accessToken: 'adult-token',
        expiresAt: DateTime.utc(2030),
        owner: SessionOwner(
          'adult-A',
          role,
          careLinkId: role == SessionRole.caregiver ? null : 'link-A',
        ),
      );

  IntakeApi api(Future<http.Response> Function(http.Request) handler) {
    final client = ApiClient(
      baseUrl: Uri.parse('https://example.com/'),
      client: MockClient(handler),
    );
    addTearDown(client.close);
    return IntakeApi(client);
  }

  group('touch confirmation', () {
    test('posts TOUCH with the adult bearer and returns the receipt', () async {
      final repo = RemoteIntakeConfirmation(
        api: api((request) async {
          expect(request.method, 'POST');
          expect(request.url.path, '/api/v1/intakes/intake-1/confirmation');
          expect(request.headers['Authorization'], 'Bearer adult-token');
          expect(jsonDecode(request.body), {'channel': 'TOUCH'});
          return _json(evidence(status: 'LATE'), 200);
        }),
        store: MemorySessionStore(session()),
      );
      final result = await ConfirmIntake(repo)('intake-1');
      final receipt = (result as AppSuccess<ConfirmationReceipt>).value;
      expect(receipt.intake.status, IntakeStatus.late);
      expect(receipt.intake.confirmedAt, DateTime.utc(2026, 11, 3, 12, 58));
      expect(receipt.alreadyConfirmed, isFalse);
    });

    test('an idempotent replay is reported as already confirmed', () async {
      final repo = RemoteIntakeConfirmation(
        api: api((_) async => _json(evidence(alreadyConfirmed: true), 200)),
        store: MemorySessionStore(session()),
      );
      final result = await ConfirmIntake(repo)('intake-1');
      expect(
        (result as AppSuccess<ConfirmationReceipt>).value.alreadyConfirmed,
        isTrue,
      );
    });

    test('409 INTAKE_NOT_CONFIRMABLE keeps its stable code', () async {
      final repo = RemoteIntakeConfirmation(
        api: api(
          (_) async =>
              _json({'title': 'INTAKE_NOT_CONFIRMABLE', 'status': 409}, 409),
        ),
        store: MemorySessionStore(session()),
      );
      final result = await ConfirmIntake(repo)('intake-1');
      expect((result as AppFailure).code, 'INTAKE_NOT_CONFIRMABLE');
    });

    test(
      'a receipt for another dose, adult or a pending status is rejected',
      () async {
        for (final body in [
          evidence(id: 'intake-2'),
          evidence(adult: 'adult-B'),
          evidence(status: 'PENDING'),
        ]) {
          final repo = RemoteIntakeConfirmation(
            api: api((_) async => _json(body, 200)),
            store: MemorySessionStore(session()),
          );
          final result = await ConfirmIntake(repo)('intake-1');
          expect((result as AppFailure).code, 'INVALID_RESPONSE');
        }
      },
    );

    test('caregiver and setup sessions cannot confirm for the adult', () async {
      var calls = 0;
      for (final role in [SessionRole.caregiver, SessionRole.linkSetup]) {
        final repo = RemoteIntakeConfirmation(
          api: api((_) async {
            calls++;
            return _json(evidence(), 200);
          }),
          store: MemorySessionStore(session(role)),
        );
        final result = await ConfirmIntake(repo)('intake-1');
        expect((result as AppFailure).code, 'ACCESS_DENIED');
      }
      expect(calls, 0);
    });
  });

  group('dose detail', () {
    test('reads one dose and maps 404 to INTAKE_NOT_FOUND', () async {
      final ok = RemoteIntakeReader(
        api: api((request) async {
          expect(request.url.path, '/api/v1/intakes/intake-1');
          return _json(evidence(status: 'PENDING'), 200);
        }),
        store: MemorySessionStore(session()),
      );
      final found = await GetIntakeDetail(ok)('intake-1');
      expect((found as AppSuccess<Intake>).value.confirmable, isTrue);

      final missing = RemoteIntakeReader(
        api: api((_) async => _json({'title': 'INTAKE_NOT_FOUND'}, 404)),
        store: MemorySessionStore(session()),
      );
      final result = await GetIntakeDetail(missing)('intake-1');
      expect((result as AppFailure).code, 'INTAKE_NOT_FOUND');
    });
  });

  test('evidence that contradicts its status is rejected', () {
    final confirmedWithoutInstant = evidence()..['confirmedAt'] = null;
    final pendingWithInstant = evidence(status: 'PENDING')
      ..['confirmedAt'] = '2026-11-03T12:58:00Z';
    for (final body in [confirmedWithoutInstant, pendingWithInstant]) {
      expect(() => IntakeMapper.intake(body), throwsFormatException);
    }
  });

  group('AgendaWeek', () {
    test('starts on Monday and spans seven local days', () {
      final week = AgendaWeek.containing(DateTime(2026, 11, 5, 15));
      expect(week.start, DateTime(2026, 11, 2));
      expect(week.days.last, DateTime(2026, 11, 8));
      expect(week.from, DateTime(2026, 11, 2).toUtc());
      expect(week.to, DateTime(2026, 11, 9).toUtc());
      expect(week.contains(DateTime(2026, 11, 8, 23, 59)), isTrue);
      expect(week.contains(DateTime(2026, 11, 9)), isFalse);
    });

    test('a Sunday belongs to the week that started the Monday before', () {
      expect(
        AgendaWeek.containing(DateTime(2026, 11, 8)).start,
        DateTime(2026, 11, 2),
      );
      expect(
        AgendaWeek.containing(DateTime(2026, 11, 2)).shift(-1).start,
        DateTime(2026, 10, 26),
      );
    });
  });
}
