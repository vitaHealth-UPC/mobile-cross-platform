import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tata/features/omission_escalation/application/readmodels/omission_push_payload.dart';
import 'package:tata/features/omission_escalation/domain/value_objects/omission_push.dart';
import 'package:tata/features/omission_escalation/infrastructure/push/firebase_omission_message_source.dart';

const _data = <String, dynamic>{
  'schemaVersion': '1',
  'kind': 'CAREGIVER_ALERT',
  'olderAdultId': 'adult-a',
  'deliveryId': 'delivery-a',
  'intakeId': 'dose-a',
  'medicationName': 'Medication',
  'scheduledAt': '2026-11-23T10:00:00Z',
};

class _Messaging implements FirebaseMessaging {
  RemoteMessage? initial;
  @override
  Future<RemoteMessage?> getInitialMessage() async => initial;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test(
    'foreground mapping rejects unsupported schemas and malformed data',
    () async {
      final source = FirebaseOmissionMessageSource(
        foreground: Stream.fromIterable([
          const RemoteMessage(data: _data),
          RemoteMessage(data: {..._data, 'schemaVersion': '2'}),
          RemoteMessage(data: {..._data, 'intakeId': 123}),
          const RemoteMessage(
            notification: RemoteNotification(body: 'A pending dose'),
          ),
        ]),
      );
      final messages = await source.received.toList();
      expect(messages, hasLength(1));
      expect(messages.single.kind, OmissionPushKind.caregiverAlert);
      expect(messages.single.intakeId, 'dose-a');
    },
  );

  test(
    'remote tap preserves the exact reference for later authorization',
    () async {
      final source = FirebaseOmissionMessageSource(
        opened: Stream.value(const RemoteMessage(data: _data)),
      );
      final payload = await source.opened.first;
      final query = OmissionPushPayload.decode(payload)!;
      expect(query.olderAdultId, 'adult-a');
      expect(query.intakeId, 'dose-a');
    },
  );

  test(
    'initial remote message is mapped without trusting visible text',
    () async {
      final sdk = _Messaging()..initial = const RemoteMessage(data: _data);
      var initializations = 0;
      final source = FirebaseOmissionMessageSource(
        supported: true,
        messaging: () async {
          initializations++;
          return sdk;
        },
      );
      expect(await source.initialize(), isTrue);
      final query = OmissionPushPayload.decode(await source.initialPayload())!;
      expect(query.intakeId, 'dose-a');
      expect(initializations, 1);
    },
  );

  test('missing Firebase configuration leaves delivery disabled', () async {
    final source = FirebaseOmissionMessageSource(
      supported: true,
      messaging: () async => throw Exception('configuration unavailable'),
    );
    expect(await source.initialize(), isFalse);
    expect(await source.initialPayload(), isNull);
  });

  test('unsupported targets never initialize native messaging', () async {
    final source = FirebaseOmissionMessageSource(
      supported: false,
      messaging: () => throw StateError('must not initialize'),
    );
    expect(await source.initialize(), isFalse);
    expect(await source.initialPayload(), isNull);
  });
}
