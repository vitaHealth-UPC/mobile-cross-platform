import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tata/features/treatment_management/application/usecases/medication_usecases.dart';
import 'package:tata/features/treatment_management/application/usecases/treatment_usecases.dart';
import 'package:tata/features/treatment_management/domain/value_objects/treatment_status.dart';
import 'package:tata/features/treatment_management/infrastructure/remote/treatment_api.dart';
import 'package:tata/features/treatment_management/infrastructure/repositories/remote_medication_management_repository.dart';
import 'package:tata/features/treatment_management/infrastructure/repositories/remote_treatment_lifecycle_repository.dart';
import 'package:tata/features/treatment_management/infrastructure/repositories/remote_treatment_readers.dart';
import 'package:tata/features/treatment_management/infrastructure/repositories/remote_treatment_repository.dart';
import 'package:tata/shared/application/session/session_owner.dart';
import 'package:tata/shared/application/session/stored_session.dart';
import 'package:tata/shared/common/result/app_result.dart';
import 'package:tata/shared/infrastructure/network/api_client.dart';

import '../support/memory_session_store.dart';

void main() {
  StoredSession caregiver() => StoredSession(
    accessToken: 'token-A',
    expiresAt: DateTime.utc(2030),
    owner: SessionOwner('caregiver-A', SessionRole.caregiver),
  );
  StoredSession adult() => StoredSession(
    accessToken: 'token-B',
    expiresAt: DateTime.utc(2030),
    owner: SessionOwner('adult-A', SessionRole.olderAdult, careLinkId: 'link'),
  );

  TreatmentApi apiFor(Future<http.Response> Function(http.Request) handler) {
    final client = ApiClient(
      baseUrl: Uri.parse('https://example.com/'),
      client: MockClient(handler),
    );
    addTearDown(client.close);
    return TreatmentApi(client);
  }

  Map<String, Object?> medication({bool active = true, String id = 'med-1'}) =>
      {
        'id': id,
        'olderAdultId': 'adult-A',
        'name': 'Metformina',
        'presentation': '500 mg',
        'active': active,
      };

  Map<String, Object?> treatment({
    String status = 'DRAFT',
    Map<String, Object?> extra = const {},
  }) => {
    'id': 'tr-1',
    'olderAdultId': 'adult-A',
    'name': 'Diabetes',
    'status': status,
    ...extra,
  };

  group('medications', () {
    test(
      'registration sends the captured caregiver and validates the receipt',
      () async {
        final store = MemorySessionStore(caregiver());
        final api = apiFor((request) async {
          expect(request.method, 'POST');
          expect(request.url.path, '/api/v1/older-adults/adult-A/medications');
          expect(request.headers['Authorization'], 'Bearer token-A');
          expect(jsonDecode(request.body), {
            'caregiverId': 'caregiver-A',
            'name': 'Metformina',
            'presentation': '500 mg',
          });
          return http.Response(jsonEncode(medication()), 201);
        });
        final result = await RegisterMedication(
          RemoteTreatmentRepository(api: api, store: store),
        )(' adult-A ', ' Metformina ', ' 500 mg ');
        expect(result, isA<AppSuccess>());
        expect((result as AppSuccess).value.label, contains('Metformina'));
      },
    );

    test('blank fields never reach the network', () async {
      var calls = 0;
      final api = apiFor((_) async {
        calls++;
        return http.Response('{}', 200);
      });
      final result = await RegisterMedication(
        RemoteTreatmentRepository(
          api: api,
          store: MemorySessionStore(caregiver()),
        ),
      )('adult-A', '  ', 'x');
      expect((result as AppFailure).code, 'REQUIRED_FIELDS_MISSING');
      expect(calls, 0);
    });

    test('an older adult session cannot manage medications', () async {
      var calls = 0;
      final api = apiFor((_) async {
        calls++;
        return http.Response('[]', 200);
      });
      final result = await ListMedications(
        RemoteMedicationManagementRepository(
          api: api,
          store: MemorySessionStore(adult()),
        ),
      )('adult-A');
      expect(result, isA<AppFailure>());
      expect(calls, 0);
    });

    test('a receipt for another adult is rejected as invalid', () async {
      final api = apiFor(
        (_) async => http.Response(
          jsonEncode({...medication(), 'olderAdultId': 'adult-B'}),
          201,
        ),
      );
      final result = await RegisterMedication(
        RemoteTreatmentRepository(
          api: api,
          store: MemorySessionStore(caregiver()),
        ),
      )('adult-A', 'Metformina', '500 mg');
      expect((result as AppFailure).code, 'INVALID_RESPONSE');
    });

    test('deactivation must be acknowledged as inactive', () async {
      final api = apiFor((request) async {
        expect(request.url.path, '/api/v1/medications/med-1/deactivation');
        expect(request.url.queryParameters, {'caregiverId': 'caregiver-A'});
        return http.Response(jsonEncode(medication(active: true)), 200);
      });
      final result = await DeactivateMedication(
        RemoteMedicationManagementRepository(
          api: api,
          store: MemorySessionStore(caregiver()),
        ),
      )('med-1');
      expect(result, isA<AppFailure>());
    });

    test('server rejections map to stable codes', () async {
      for (final (status, code) in [
        (400, 'REQUEST_VALIDATION_FAILED'),
        (404, 'RESOURCE_NOT_FOUND'),
        (409, 'CONFLICT'),
        (500, 'REQUEST_FAILED'),
      ]) {
        final api = apiFor((_) async => http.Response('{}', status));
        final result = await ListMedications(
          RemoteMedicationManagementRepository(
            api: api,
            store: MemorySessionStore(caregiver()),
          ),
        )('adult-A');
        expect((result as AppFailure).code, code, reason: '$status');
      }
    });
  });

  group('treatments', () {
    test('creation requires a DRAFT receipt', () async {
      final api = apiFor(
        (_) async =>
            http.Response(jsonEncode(treatment(status: 'ACTIVE')), 201),
      );
      final result = await CreateTreatment(
        RemoteTreatmentRepository(
          api: api,
          store: MemorySessionStore(caregiver()),
        ),
      )('adult-A', 'Diabetes');
      expect(result, isA<AppFailure>());
    });

    test('configure validates the regimen and compares the receipt', () async {
      final api = apiFor((request) async {
        expect(request.method, 'PUT');
        expect(request.url.path, '/api/v1/treatments/tr-1/regimen');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['scheduledTimes'], ['08:00', '20:00']);
        expect(body['caregiverId'], 'caregiver-A');
        expect(body.containsKey('followUpDelayMinutes'), isFalse);
        return http.Response(
          jsonEncode(
            treatment(
              status: 'DRAFT',
              extra: {
                'medicationId': 'med-1',
                'dose': '1 tableta',
                'frequency': 'cada 12 horas',
                // The backend answers seconds; they are normalized.
                'scheduledTimes': ['20:00:00', '08:00:00'],
                'instructions': 'Con comida',
                'reminderLeadMinutes': 0,
              },
            ),
          ),
          200,
        );
      });
      final result =
          await ConfigureTreatment(
            RemoteTreatmentLifecycleRepository(
              api: api,
              store: MemorySessionStore(caregiver()),
            ),
          )(
            'tr-1',
            'med-1',
            const RegimenDraft(
              dose: '1 tableta',
              frequency: 'cada 12 horas',
              scheduleText: '20:00, 8:00',
              instructions: 'Con comida',
            ),
          );
      expect(result, isA<AppSuccess>());
    });

    test('an invalid regimen is refused before any request', () async {
      var calls = 0;
      final api = apiFor((_) async {
        calls++;
        return http.Response('{}', 200);
      });
      final configure = ConfigureTreatment(
        RemoteTreatmentLifecycleRepository(
          api: api,
          store: MemorySessionStore(caregiver()),
        ),
      );
      for (final draft in [
        const RegimenDraft(
          dose: '',
          frequency: 'x',
          scheduleText: '08:00',
          instructions: '',
        ),
        const RegimenDraft(
          dose: 'x',
          frequency: 'x',
          scheduleText: '25:00',
          instructions: '',
        ),
        const RegimenDraft(
          dose: 'x',
          frequency: 'x',
          scheduleText: '',
          instructions: '',
        ),
        const RegimenDraft(
          dose: 'x',
          frequency: 'x',
          scheduleText: '08:00',
          instructions: '',
          followUpDelayMinutes: 1441,
        ),
      ]) {
        final result = await configure('tr-1', 'med-1', draft);
        expect((result as AppFailure).code, 'INVALID_TREATMENT_CONFIGURATION');
      }
      expect(calls, 0);
    });

    test('a receipt that does not echo the regimen is rejected', () async {
      final api = apiFor(
        (_) async => http.Response(
          jsonEncode(
            treatment(
              extra: {
                'medicationId': 'med-1',
                'dose': 'OTRA',
                'frequency': 'f',
                'scheduledTimes': ['08:00'],
                'instructions': '',
                'reminderLeadMinutes': 0,
              },
            ),
          ),
          200,
        ),
      );
      final result =
          await ConfigureTreatment(
            RemoteTreatmentLifecycleRepository(
              api: api,
              store: MemorySessionStore(caregiver()),
            ),
          )(
            'tr-1',
            'med-1',
            const RegimenDraft(
              dose: 'x',
              frequency: 'f',
              scheduleText: '08:00',
              instructions: '',
            ),
          );
      expect((result as AppFailure).code, 'INVALID_RESPONSE');
    });

    test('pause must be acknowledged as PAUSED', () async {
      Future<AppResult> pause(String status) {
        final api = apiFor((request) async {
          expect(request.url.path, '/api/v1/treatments/tr-1/pause');
          return http.Response(jsonEncode(treatment(status: status)), 200);
        });
        return ChangeTreatmentStatus(
          RemoteTreatmentLifecycleRepository(
            api: api,
            store: MemorySessionStore(caregiver()),
          ),
        )('tr-1', TreatmentLifecycleAction.pause);
      }

      final ok = await pause('PAUSED');
      expect((ok as AppSuccess).value.status, TreatmentStatus.paused);
      expect(await pause('ACTIVE'), isA<AppFailure>());
    });

    test('list rejects unknown statuses and duplicate treatments', () async {
      final unknown = apiFor(
        (_) async =>
            http.Response(jsonEncode([treatment(status: 'ARCHIVED')]), 200),
      );
      final reader = RemoteTreatmentReader(
        api: unknown,
        store: MemorySessionStore(caregiver()),
      );
      expect((await reader.list('adult-A')), isA<AppFailure>());

      final duplicate = apiFor(
        (_) async => http.Response(jsonEncode([treatment(), treatment()]), 200),
      );
      expect(
        await RemoteTreatmentReader(
          api: duplicate,
          store: MemorySessionStore(caregiver()),
        ).list('adult-A'),
        isA<AppFailure>(),
      );
    });
  });

  group('my medications', () {
    test('a medication is active only with an active treatment', () async {
      final api = apiFor((request) async {
        expect(request.url.path, '/api/v1/me/medications');
        expect(request.headers['Authorization'], 'Bearer token-B');
        return http.Response(
          jsonEncode([
            {
              'medication': medication(),
              'treatments': [
                treatment(
                  status: 'ACTIVE',
                  extra: {
                    'medicationId': 'med-1',
                    'dose': '1 tableta',
                    'frequency': 'f',
                    'scheduledTimes': ['08:00:00'],
                    'instructions': '',
                  },
                ),
              ],
            },
            {'medication': medication(id: 'med-2'), 'treatments': []},
          ]),
          200,
        );
      });
      final result = await RemoteMyMedicationsReader(
        api: api,
        store: MemorySessionStore(adult()),
      ).list();
      final items = (result as AppSuccess).value;
      expect(items, hasLength(2));
      expect(items.first.active, isTrue);
      expect(items.first.scheduleLabel, '08:00');
      expect(items.last.active, isFalse);
    });

    test('a caregiver session cannot read the adult catalog', () async {
      var calls = 0;
      final api = apiFor((_) async {
        calls++;
        return http.Response('[]', 200);
      });
      final result = await RemoteMyMedicationsReader(
        api: api,
        store: MemorySessionStore(caregiver()),
      ).list();
      expect(result, isA<AppFailure>());
      expect(calls, 0);
    });
  });
}
