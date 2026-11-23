import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tata/features/treatment_management/application/readmodels/treatment_readmodels.dart';
import 'package:tata/features/treatment_management/infrastructure/mappers/treatment_mapper.dart';
import 'package:tata/features/treatment_management/infrastructure/remote/treatment_api.dart';
import 'package:tata/features/treatment_management/infrastructure/repositories/remote_treatment_readers.dart';
import 'package:tata/shared/application/session/session_owner.dart';
import 'package:tata/shared/application/session/stored_session.dart';
import 'package:tata/shared/common/result/app_result.dart';
import 'package:tata/shared/infrastructure/network/api_client.dart';

import '../support/memory_session_store.dart';
import 'catalog_fixtures.dart';

StoredSession _session([SessionRole role = SessionRole.olderAdult]) =>
    StoredSession(
      accessToken: 'test-token',
      expiresAt: DateTime.utc(2030),
      owner: SessionOwner(
        'adult-A',
        role,
        careLinkId: role == SessionRole.caregiver ? null : 'link-A',
      ),
    );
http.Response _json(Object? value, [int status = 200]) => http.Response.bytes(
  utf8.encode(jsonEncode(value)),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

void main() {
  RemoteMyMedicationsReader repository(
    MemorySessionStore store,
    Future<http.Response> Function(http.Request) handle,
  ) {
    final client = ApiClient(
      baseUrl: Uri.parse('https://example.com/'),
      client: MockClient(handle),
    );
    addTearDown(client.close);
    return RemoteMyMedicationsReader(api: TreatmentApi(client), store: store);
  }

  test(
    'adult catalog uses bearer identity without caregiver query parameters',
    () async {
      final repo = repository(MemorySessionStore(_session()), (request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/api/v1/me/medications');
        expect(request.url.query, isEmpty);
        expect(request.headers['Authorization'], 'Bearer test-token');
        return _json([catalogJson()]);
      });
      final result = await repo.list() as AppSuccess<List<MyMedication>>;
      expect(result.value.single.name, 'Losartán 50 mg');
      expect(
        result.value.single.treatments.single.recurrenceZone,
        'America/Lima',
      );
    },
  );
  test('empty catalog is distinct from failed request', () async {
    final repo = repository(
      MemorySessionStore(_session()),
      (_) async => _json([]),
    );
    expect(
      (await repo.list() as AppSuccess<List<MyMedication>>).value,
      isEmpty,
    );
  });
  test('caregiver and setup sessions cannot read the adult catalog', () async {
    var calls = 0;
    for (final role in [SessionRole.caregiver, SessionRole.linkSetup]) {
      final repo = repository(MemorySessionStore(_session(role)), (_) async {
        calls++;
        return _json([]);
      });
      expect((await repo.list() as AppFailure).code, 'ACCESS_DENIED');
    }
    expect(calls, 0);
  });
  test(
    '401 clears only the captured session while 403 preserves credentials',
    () async {
      for (final status in [401, 403]) {
        final store = MemorySessionStore(_session());
        final repo = repository(store, (_) async => _json({}, status));
        expect(
          (await repo.list() as AppFailure).code,
          status == 401 ? 'AUTHENTICATION_REQUIRED' : 'ACCESS_DENIED',
        );
        expect(store.current == null, status == 401);
      }
    },
  );
  test('late catalog cannot leak through a replaced session', () async {
    final response = Completer<http.Response>();
    final started = Completer<void>();
    final store = MemorySessionStore(_session());
    final repo = repository(store, (_) {
      started.complete();
      return response.future;
    });
    final pending = repo.list();
    await started.future;
    await store.replace(_session(), expectedGeneration: store.generation);
    response.complete(_json([catalogJson()]));
    expect((await pending as AppFailure).code, 'SESSION_CHANGED');
  });
  test(
    'catalog validates owner, relations, statuses and scheduled time syntax',
    () {
      for (final change in <void Function(Map<String, Object?>)>[
        (row) => (row['medication']! as Map)['olderAdultId'] = 'another-adult',
        (row) => ((row['treatments']! as List).first as Map)['medicationId'] =
            'another-medication',
        (row) =>
            ((row['treatments']! as List).first as Map)['status'] = 'UNKNOWN',
        (row) => ((row['treatments']! as List).first as Map)['scheduledTimes'] =
            ['25:00'],
        (row) =>
            ((row['treatments']! as List).first as Map)['scheduledTimes'] = [],
        (row) =>
            ((row['treatments']! as List).first as Map)['instructions'] = 1,
      ]) {
        final row = catalogJson();
        change(row);
        expect(
          () => TreatmentMapper.myMedications([row], ownerId: 'adult-A'),
          throwsFormatException,
        );
      }
      expect(
        () => TreatmentMapper.myMedications([
          catalogJson(),
          catalogJson(),
        ], ownerId: 'adult-A'),
        throwsFormatException,
      );
    },
  );
  test('configured draft and paused regimens belong to history', () {
    for (final status in ['DRAFT', 'PAUSED']) {
      expect(
        TreatmentMapper.myMedications([
          catalogJson(status: status),
        ], ownerId: 'adult-A').single.active,
        isFalse,
      );
    }
  });
}
