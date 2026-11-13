import 'package:flutter_test/flutter_test.dart';
import 'package:tata/features/omission_escalation/application/policies/omission_push_access_policy.dart';
import 'package:tata/features/omission_escalation/application/policies/omission_push_topics.dart';
import 'package:tata/features/omission_escalation/application/readmodels/omission_push_payload.dart';
import 'package:tata/features/omission_escalation/application/readmodels/push_destination.dart';
import 'package:tata/features/omission_escalation/application/usecases/omission_usecases.dart';
import 'package:tata/features/omission_escalation/domain/value_objects/omission_push.dart';
import 'package:tata/features/omission_escalation/infrastructure/push/omission_push_data_mapper.dart';
import 'package:tata/shared/application/session/session_owner.dart';
import 'package:tata/shared/application/session/stored_session.dart';
import 'package:tata/shared/common/result/app_result.dart';

import '../support/memory_session_store.dart';
import 'omission_fakes.dart';

void main() {
  group('legacy topic messages', () {
    test(
      'a caregiver topic yields an alert with the medication of its text',
      () {
        final push = OmissionPushTopics.parse(
          '/topics/caregivers-of-adult-1',
          'Metformina was not confirmed. Please check how they are doing.',
        );
        expect(push?.kind, OmissionPushKind.caregiverAlert);
        expect(push?.olderAdultId, 'adult-1');
        expect(push?.medicationName, 'Metformina');
      },
    );

    test('an adult topic yields a reminder; an unknown text keeps no name', () {
      final named = OmissionPushTopics.parse(
        '/topics/user-adult-1',
        'Your Losartan is still pending. Please confirm it when you take it.',
      );
      expect(named?.kind, OmissionPushKind.reinforcedReminder);
      expect(named?.medicationName, 'Losartan');
      final other = OmissionPushTopics.parse('/topics/user-adult-1', 'Hola');
      expect(other?.medicationName, isNull);
    });

    test('anything that is not an omission topic is ignored', () {
      for (final from in [
        null,
        '',
        'caregivers-of-adult-1',
        '/topics/news',
        '/topics/user-',
        '/topics/user-a b',
        '/topics/user-a/b',
        '/topics/caregivers-of-',
      ]) {
        expect(OmissionPushTopics.parse(from, null), isNull, reason: '$from');
      }
    });

    test('topic names are built from a trimmed identifier', () {
      expect(OmissionPushTopics.forOlderAdult(' a1 '), 'user-a1');
      expect(OmissionPushTopics.forCaregiversOf(' a1 '), 'caregivers-of-a1');
    });
  });

  group('versioned data messages', () {
    Map<String, String> complete() => {
      'schemaVersion': '1',
      'kind': 'CAREGIVER_ALERT',
      'olderAdultId': 'adult-1',
      'deliveryId': 'delivery-1',
      'intakeId': 'intake-1',
      'medicationName': 'Metformina',
      'scheduledAt': '2030-01-02T08:30:00Z',
    };

    test('a complete version 1 message maps without parsing any text', () {
      final push = omissionPushFromData(complete())!;
      expect(push.kind, OmissionPushKind.caregiverAlert);
      expect(push.deliveryId, 'delivery-1');
      expect(push.intakeId, 'intake-1');
      expect(push.scheduledAt, DateTime.utc(2030, 1, 2, 8, 30));
    });

    test('any missing or invalid part discards the whole message', () {
      for (final key in complete().keys) {
        final data = complete()..remove(key);
        expect(omissionPushFromData(data), isNull, reason: 'without $key');
      }
      expect(
        omissionPushFromData({...complete(), 'schemaVersion': '2'}),
        isNull,
      );
      expect(omissionPushFromData({...complete(), 'kind': 'OTHER'}), isNull);
      expect(
        omissionPushFromData({...complete(), 'scheduledAt': 'tomorrow'}),
        isNull,
      );
      expect(omissionPushFromData({...complete(), 'intakeId': '  '}), isNull);
    });

    test('a message without a version falls back to the topic contract', () {
      final push = omissionPushFromMessage(
        data: const {},
        from: '/topics/user-adult-1',
        body: 'Your Losartan is still pending. Please confirm it when you take it.',
      );
      expect(push?.medicationName, 'Losartan');
      expect(
        omissionPushFromMessage(data: {'schemaVersion': '9'}, from: null),
        isNull,
      );
    });
  });

  group('tap payload', () {
    test('round trips the references of a notice', () {
      final payload = OmissionPushPayload.encode(
        OmissionPush(
          kind: OmissionPushKind.reinforcedReminder,
          olderAdultId: 'adult-1',
          medicationName: 'Losartan',
          intakeId: 'intake-1',
        ),
      );
      final query = OmissionPushPayload.decode(payload)!;
      expect(query.kind, OmissionPushKind.reinforcedReminder);
      expect(query.olderAdultId, 'adult-1');
      expect(query.medicationName, 'Losartan');
      expect(query.intakeId, 'intake-1');
    });

    test('untrusted or malformed payloads are not a destination', () {
      expect(OmissionPushPayload.decode(null), isNull);
      expect(OmissionPushPayload.decode('not json'), isNull);
      expect(OmissionPushPayload.decode('[1]'), isNull);
      expect(
        OmissionPushPayload.decode('{"kind":"X","olderAdultId":"a"}'),
        isNull,
      );
      expect(
        OmissionPushPayload.decode(
          '{"kind":"CAREGIVER_ALERT","olderAdultId":" "}',
        ),
        isNull,
      );
      expect(
        OmissionPushPayload.decode(
          '{"kind":"CAREGIVER_ALERT","olderAdultId":"a","intakeId":" "}',
        ),
        isNull,
      );
    });
  });

  group('recipient policy', () {
    final caregiver = StoredSession(
      accessToken: 'token-c',
      expiresAt: DateTime.utc(2030),
      owner: SessionOwner('caregiver-1', SessionRole.caregiver),
    );
    final adult = StoredSession(
      accessToken: 'token-a',
      expiresAt: DateTime.utc(2030),
      owner: SessionOwner('adult-1', SessionRole.olderAdult, careLinkId: 'l1'),
    );
    final now = DateTime.utc(2029);

    OmissionPush alert([String adultId = 'adult-1']) => OmissionPush(
      kind: OmissionPushKind.caregiverAlert,
      olderAdultId: adultId,
    );
    OmissionPush reminder([String adultId = 'adult-1']) => OmissionPush(
      kind: OmissionPushKind.reinforcedReminder,
      olderAdultId: adultId,
    );

    OmissionPushAccessPolicy policy(
      StoredSession? session, {
      Map<String, String> followed = const {},
    }) => OmissionPushAccessPolicy(
      sessions: MemorySessionStore(session),
      targets: MemoryPushTargets()..caregivers.addAll(followed),
      now: () => now,
    );

    test('without a session nothing is shown or opened', () async {
      final p = policy(null, followed: {'adult-1': 'caregiver-1'});
      expect(await p.allows(alert()), isFalse);
      expect(await p.allows(reminder()), isFalse);
    });

    test('a reminder is only for the older adult it names', () async {
      expect(await policy(adult).allows(reminder()), isTrue);
      expect(await policy(adult).allows(reminder('adult-2')), isFalse);
      expect(await policy(caregiver).allows(reminder()), isFalse);
    });

    test(
      'a caregiver alert needs the caregiver that follows that adult',
      () async {
        final followed = {'adult-1': 'caregiver-1'};
        expect(
          await policy(caregiver, followed: followed).allows(alert()),
          isTrue,
        );
        expect(await policy(caregiver).allows(alert()), isFalse);
        expect(
          await policy(caregiver, followed: followed).allows(alert('adult-2')),
          isFalse,
        );
        expect(
          await policy(adult, followed: followed).allows(alert()),
          isFalse,
        );
      },
    );

    test('an expired session shows nothing', () async {
      final expired = StoredSession(
        accessToken: 'token-a',
        expiresAt: DateTime.utc(2028),
        owner: adult.owner,
      );
      expect(await policy(expired).allows(reminder()), isFalse);
    });

    test('a stored tap is authorized again before it opens a screen', () async {
      final followed = {'adult-1': 'caregiver-1'};
      const destination = CaregiverAlertsDestination(
        caregiverId: 'caregiver-1',
        olderAdultId: 'adult-1',
      );
      expect(
        await policy(
          caregiver,
          followed: followed,
        ).allowsDestination(destination),
        isTrue,
      );
      const otherCaregiver = CaregiverAlertsDestination(
        caregiverId: 'caregiver-9',
        olderAdultId: 'adult-1',
      );
      expect(
        await policy(
          caregiver,
          followed: followed,
        ).allowsDestination(otherCaregiver),
        isFalse,
      );
      expect(
        await policy(adult).allowsDestination(
          const OlderAdultDoseDestination(
            olderAdultId: 'adult-1',
            intakeId: 'i1',
          ),
        ),
        isTrue,
      );
      expect(
        await policy(adult).allowsDestination(
          const OlderAdultHomeDestination(
            olderAdultId: 'adult-2',
            olderAdultName: 'Ana',
          ),
        ),
        isFalse,
      );
      expect(await policy(null).allowsDestination(destination), isFalse);
    });
  });

  group('follow-up commands and destinations', () {
    test('following trims and stores the target', () async {
      final targets = MemoryPushTargets();
      expect(
        await FollowCaregiverAlerts(targets)(
          caregiverId: ' c1 ',
          olderAdultId: ' a1 ',
        ),
        isA<AppSuccess<void>>(),
      );
      expect(targets.caregivers, {'a1': 'c1'});
      await FollowDoseReminders(targets)(
        olderAdultId: ' a1 ',
        olderAdultName: ' Ana ',
      );
      expect(targets.adults, {'a1': 'Ana'});
    });

    test('a blank reference is rejected without storing anything', () async {
      final targets = MemoryPushTargets();
      final first = await FollowCaregiverAlerts(targets)(
        caregiverId: ' ',
        olderAdultId: 'a1',
      );
      final second = await FollowDoseReminders(targets)(
        olderAdultId: '',
        olderAdultName: 'Ana',
      );
      expect((first as AppFailure<void>).code, invalidFollowUpReference);
      expect((second as AppFailure<void>).code, invalidFollowUpReference);
      expect(targets.caregivers, isEmpty);
      expect(targets.adults, isEmpty);
    });

    test('a caregiver alert opens the alerts of the followed adult', () async {
      final targets = MemoryPushTargets()..caregivers['a1'] = 'c1';
      final destination = await ResolvePushDestination(targets)(
        const ResolvePushDestinationQuery(
          kind: OmissionPushKind.caregiverAlert,
          olderAdultId: ' a1 ',
          medicationName: 'Metformina',
          intakeId: 'i1',
        ),
      );
      expect(destination, isA<CaregiverAlertsDestination>());
      final alerts = destination! as CaregiverAlertsDestination;
      expect(alerts.caregiverId, 'c1');
      expect(alerts.medicationName, 'Metformina');
      expect(alerts.intakeId, 'i1');
    });

    test(
      'a device that does not follow the adult has no destination',
      () async {
        final resolve = ResolvePushDestination(MemoryPushTargets());
        for (final kind in OmissionPushKind.values) {
          expect(
            await resolve(
              ResolvePushDestinationQuery(kind: kind, olderAdultId: 'a1'),
            ),
            isNull,
          );
        }
      },
    );

    test('a reminder opens its exact intake, or else the adult home', () async {
      final targets = MemoryPushTargets()..adults['a1'] = 'Ana';
      final resolve = ResolvePushDestination(targets);
      final dose = await resolve(
        const ResolvePushDestinationQuery(
          kind: OmissionPushKind.reinforcedReminder,
          olderAdultId: 'a1',
          intakeId: 'i1',
        ),
      );
      expect((dose! as OlderAdultDoseDestination).intakeId, 'i1');
      final home = await resolve(
        const ResolvePushDestinationQuery(
          kind: OmissionPushKind.reinforcedReminder,
          olderAdultId: 'a1',
        ),
      );
      expect((home! as OlderAdultHomeDestination).olderAdultName, 'Ana');
      expect(
        await resolve(
          const ResolvePushDestinationQuery(
            kind: OmissionPushKind.reinforcedReminder,
            olderAdultId: 'a1',
            intakeId: ' ',
          ),
        ),
        isNull,
      );
    });
  });

  group('incoming push', () {
    test('is shown only to its recipient', () async {
      final notifier = RecordingNotifier();
      final targets = MemoryPushTargets()..caregivers['a1'] = 'c1';
      HandleIncomingOmissionPush handler(StoredSession? session) =>
          HandleIncomingOmissionPush(
            OmissionPushAccessPolicy(
              sessions: MemorySessionStore(session),
              targets: targets,
              now: () => DateTime.utc(2029),
            ),
            notifier,
          );
      final push = OmissionPush(
        kind: OmissionPushKind.caregiverAlert,
        olderAdultId: 'a1',
        medicationName: 'Metformina',
      );
      expect(await handler(null)(push), isFalse);
      expect(
        await handler(
          StoredSession(
            accessToken: 'x',
            expiresAt: DateTime.utc(2030),
            owner: SessionOwner('c2', SessionRole.caregiver),
          ),
        )(push),
        isFalse,
      );
      expect(notifier.shown, isEmpty);
      expect(
        await handler(
          StoredSession(
            accessToken: 'x',
            expiresAt: DateTime.utc(2030),
            owner: SessionOwner('c1', SessionRole.caregiver),
          ),
        )(push),
        isTrue,
      );
      expect(notifier.shown.single.medicationName, 'Metformina');
    });
  });

  group('push value', () {
    test('rejects blank identifiers', () {
      expect(
        () => OmissionPush(
          kind: OmissionPushKind.caregiverAlert,
          olderAdultId: ' ',
        ),
        throwsArgumentError,
      );
      expect(
        () => OmissionPush(
          kind: OmissionPushKind.caregiverAlert,
          olderAdultId: 'a1',
          deliveryId: ' ',
        ),
        throwsArgumentError,
      );
      expect(
        () => OmissionPush(
          kind: OmissionPushKind.caregiverAlert,
          olderAdultId: 'a1',
          intakeId: '',
        ),
        throwsArgumentError,
      );
    });
  });
}
