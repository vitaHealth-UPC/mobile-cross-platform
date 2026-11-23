import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tata/features/omission_escalation/application/policies/omission_push_access_policy.dart';
import 'package:tata/features/omission_escalation/application/readmodels/omission_push_payload.dart';
import 'package:tata/features/omission_escalation/application/readmodels/push_destination.dart';
import 'package:tata/features/omission_escalation/application/services/omission_notification_session_cleanup.dart';
import 'package:tata/features/omission_escalation/application/services/omission_push_facade.dart';
import 'package:tata/features/omission_escalation/application/services/push_device_registration_coordinator.dart';
import 'package:tata/features/omission_escalation/application/usecases/omission_usecases.dart';
import 'package:tata/features/omission_escalation/domain/value_objects/omission_push.dart';
import 'package:tata/features/omission_escalation/presentation/texts/omission_notice_text.dart';
import 'package:tata/features/omission_escalation/presentation/widgets/follow_omission_push.dart';
import 'package:tata/l10n/generated/app_localizations.dart';
import 'package:tata/shared/application/session/session_owner.dart';
import 'package:tata/shared/application/session/stored_session.dart';
import 'package:tata/shared/common/result/app_result.dart';

import '../support/memory_session_store.dart';
import 'omission_fakes.dart';

StoredSession _session(
  String id,
  SessionRole role, {
  String token = 'token',
  DateTime? expiresAt,
}) => StoredSession(
  accessToken: token,
  expiresAt: expiresAt ?? DateTime.now().add(const Duration(days: 1)),
  owner: role == SessionRole.caregiver
      ? SessionOwner(id, role)
      : SessionOwner(id, role, careLinkId: 'link'),
);

void main() {
  group('device registration coordinator', () {
    late MemorySessionStore store;
    late RecordingRegistry registry;
    late List<Duration> waits;

    PushDeviceRegistrationCoordinator coordinator(
      ScriptedTokenSource tokens, {
      void Function(Duration)? onWait,
      Duration tokenTimeout = const Duration(seconds: 10),
    }) => PushDeviceRegistrationCoordinator(
      sessions: store,
      tokens: tokens,
      registry: registry,
      tokenTimeout: tokenTimeout,
      wait: (delay) async {
        waits.add(delay);
        onWait?.call(delay);
      },
    );

    setUp(() {
      store = MemorySessionStore(_session('c1', SessionRole.caregiver));
      registry = RecordingRegistry();
      waits = [];
    });

    test('registers the token for the session in force', () async {
      await coordinator(ScriptedTokenSource([const AppSuccess('fcm-1')]))
          .synchronize();
      expect(registry.registered, hasLength(1));
      expect(registry.registered.single.token, 'fcm-1');
      expect(registry.registered.single.session, same(store.value));
    });

    test('a build without push registers nothing and does not retry', () async {
      final tokens = ScriptedTokenSource([const AppSuccess(null)]);
      await coordinator(tokens).synchronize();
      expect(registry.registered, isEmpty);
      expect(tokens.calls, 1);
      expect(waits, isEmpty);
    });

    test(
      'without a session, or with a link setup one, nothing happens',
      () async {
        final tokens = ScriptedTokenSource([const AppSuccess('fcm-1')]);
        store.value = null;
        await coordinator(tokens).synchronize();
        store.value = _session('a1', SessionRole.linkSetup);
        await coordinator(tokens).synchronize();
        expect(tokens.calls, 0);
        expect(registry.registered, isEmpty);
      },
    );

    test(
      'retries transient failures with the configured backoff and then stops',
      () async {
        registry = RecordingRegistry([const AppFailure('NETWORK_UNAVAILABLE')]);
        await coordinator(ScriptedTokenSource([const AppSuccess('fcm-1')]))
            .synchronize();
        expect(registry.registered, hasLength(4));
        expect(waits, const [
          Duration(seconds: 5),
          Duration(seconds: 15),
          Duration(seconds: 60),
        ]);
      },
    );

    test('stops retrying as soon as a registration is acknowledged', () async {
      registry = RecordingRegistry([
        const AppFailure('REQUEST_FAILED'),
        const AppSuccess(null),
      ]);
      await coordinator(ScriptedTokenSource([const AppSuccess('fcm-1')]))
          .synchronize();
      expect(registry.registered, hasLength(2));
      expect(waits, hasLength(1));
    });

    test('does not retry what a retry cannot fix', () async {
      for (final code in [
        'ACCESS_DENIED',
        'INVALID_DEVICE_TOKEN',
        'SESSION_CHANGED',
      ]) {
        registry = RecordingRegistry([AppFailure(code)]);
        waits.clear();
        await coordinator(ScriptedTokenSource([const AppSuccess('fcm-1')]))
            .synchronize();
        expect(registry.registered, hasLength(1), reason: code);
        expect(waits, isEmpty, reason: code);
      }
    });

    test('a token that cannot be read is retried', () async {
      final tokens = ScriptedTokenSource([
        const AppFailure('PUSH_TOKEN_UNAVAILABLE'),
        const AppSuccess('fcm-2'),
      ]);
      await coordinator(tokens).synchronize();
      expect(tokens.calls, 2);
      expect(registry.registered.single.token, 'fcm-2');
    });

    test('a token source that never answers is bounded by a timeout', () async {
      final tokens = ScriptedTokenSource(const [], hangs: true);
      await coordinator(
        tokens,
        tokenTimeout: const Duration(milliseconds: 5),
      ).synchronize();
      expect(tokens.calls, 4);
      expect(registry.registered, isEmpty);
    });

    test(
      'a session that changes during the backoff stops the retries',
      () async {
        registry = RecordingRegistry([const AppFailure('NETWORK_UNAVAILABLE')]);
        await coordinator(
          ScriptedTokenSource([const AppSuccess('fcm-1')]),
          onWait: (_) => store.value = _session('c2', SessionRole.caregiver),
        ).synchronize();
        expect(registry.registered, hasLength(1));
      },
    );

    test(
      'a rotated token is registered at once and reused afterwards',
      () async {
        final tokens = ScriptedTokenSource([const AppSuccess('fcm-1')]);
        final instance = coordinator(tokens);
        await instance.onNewToken('fcm-rotated');
        expect(registry.registered.single.token, 'fcm-rotated');
        expect(tokens.calls, 0);
      },
    );

    test(
      'sign-out removes the installation only if one was registered',
      () async {
        final instance = coordinator(
          ScriptedTokenSource([const AppSuccess('fcm-1')]),
        );
        await instance.beforeSignOut();
        expect(registry.unregistered, isEmpty);

        store.value = _session('c1', SessionRole.caregiver, token: 'second');
        await instance.synchronize();
        await instance.beforeSignOut();
        expect(registry.unregistered, hasLength(1));
        expect(registry.unregistered.single?.accessToken, 'second');

        // The credential being closed is never used to register again.
        await instance.synchronize();
        expect(registry.registered, hasLength(1));
      },
    );

    test('sign-out does not wait for an unavailable transport', () async {
      final stuck = _HangingRegistry();
      final instance = PushDeviceRegistrationCoordinator(
        sessions: store,
        tokens: ScriptedTokenSource([const AppSuccess('fcm-1')]),
        registry: stuck,
        unregisterTimeout: const Duration(milliseconds: 5),
      );
      await instance.synchronize();
      await instance.beforeSignOut();
      expect(stuck.unregisterCalls, 1);
    });
  });

  group('notification session cleanup', () {
    test(
      'clears on the first observation and when the owner changes',
      () async {
        final notifier = RecordingNotifier();
        final cleanup = OmissionNotificationSessionCleanup(notifier: notifier);
        addTearDown(cleanup.dispose);

        await cleanup.observe(null);
        expect(notifier.cleared, 1);
        await cleanup.observe(null);
        expect(notifier.cleared, 1);

        await cleanup.observe(_session('c1', SessionRole.caregiver));
        expect(notifier.cleared, 2);
        await cleanup.observe(
          _session('c1', SessionRole.caregiver, token: 'new'),
        );
        expect(notifier.cleared, 2, reason: 'same owner, refreshed credential');

        await cleanup.observe(_session('c2', SessionRole.caregiver));
        expect(notifier.cleared, 3);
        await cleanup.observe(null);
        expect(notifier.cleared, 4);
      },
    );

    test('a link setup session counts as no session', () async {
      final notifier = RecordingNotifier();
      final cleanup = OmissionNotificationSessionCleanup(notifier: notifier);
      addTearDown(cleanup.dispose);
      await cleanup.observe(null);
      await cleanup.observe(_session('a1', SessionRole.linkSetup));
      expect(notifier.cleared, 1);
    });

    test('clears when the credential expires', () async {
      final notifier = RecordingNotifier();
      final cleanup = OmissionNotificationSessionCleanup(notifier: notifier);
      addTearDown(cleanup.dispose);
      await cleanup.observe(
        _session(
          'c1',
          SessionRole.caregiver,
          expiresAt: DateTime.now().add(const Duration(milliseconds: 30)),
        ),
      );
      expect(notifier.cleared, 1);
      await Future<void>.delayed(const Duration(milliseconds: 150));
      expect(notifier.cleared, 2);
    });
  });

  group('facade', () {
    OmissionPushFacade build(
      MemorySessionStore store,
      MemoryPushTargets targets,
      RecordingNotifier notifier,
      RecordingRegistry registry, {
      bool enabled = true,
      ScriptedTokenSource? tokens,
    }) {
      final policy = OmissionPushAccessPolicy(
        sessions: store,
        targets: targets,
      );
      return OmissionPushFacade(
        policy: policy,
        followCaregiver: FollowCaregiverAlerts(targets),
        followReminders: FollowDoseReminders(targets),
        resolve: ResolvePushDestination(targets),
        handle: HandleIncomingOmissionPush(policy, notifier),
        registration: PushDeviceRegistrationCoordinator(
          sessions: store,
          tokens: tokens ?? ScriptedTokenSource([const AppSuccess('fcm-1')]),
          registry: registry,
          wait: (_) async {},
        ),
        cleanup: OmissionNotificationSessionCleanup(notifier: notifier),
        registrationEnabled: enabled,
      );
    }

    test(
      'following a person registers the device and enables their alerts',
      () async {
        final store = MemorySessionStore(_session('c1', SessionRole.caregiver));
        final registry = RecordingRegistry();
        final notifier = RecordingNotifier();
        final facade = build(store, MemoryPushTargets(), notifier, registry);
        addTearDown(facade.dispose);

        final alert = OmissionPush(
          kind: OmissionPushKind.caregiverAlert,
          olderAdultId: 'a1',
          medicationName: 'Metformina',
          intakeId: 'i1',
        );
        expect(await facade.canDisplay(alert), isFalse);
        await facade.followCaregiver('c1', 'a1');
        expect(registry.registered, hasLength(1));
        expect(await facade.canDisplay(alert), isTrue);
        expect(await facade.onPush(alert), isTrue);
        expect(notifier.shown, hasLength(1));

        final destination = await facade.destination(
          OmissionPushPayload.encode(alert),
        );
        expect(destination, isA<CaregiverAlertsDestination>());
        expect(await facade.canOpen(destination!), isTrue);
        expect(await facade.destination('garbage'), isNull);
      },
    );

    test('a payload is not a destination once the session changed', () async {
      final store = MemorySessionStore(_session('c1', SessionRole.caregiver));
      final facade = build(
        store,
        MemoryPushTargets(),
        RecordingNotifier(),
        RecordingRegistry(),
      );
      addTearDown(facade.dispose);
      await facade.followCaregiver('c1', 'a1');
      final payload = OmissionPushPayload.encode(
        OmissionPush(kind: OmissionPushKind.caregiverAlert, olderAdultId: 'a1'),
      );
      expect(await facade.destination(payload), isNotNull);
      store.value = _session('c2', SessionRole.caregiver);
      expect(await facade.destination(payload), isNull);
      store.value = null;
      expect(await facade.destination(payload), isNull);
    });

    test('a build without push never touches the registration', () async {
      final store = MemorySessionStore(_session('a1', SessionRole.olderAdult));
      final registry = RecordingRegistry();
      final facade = build(
        store,
        MemoryPushTargets(),
        RecordingNotifier(),
        registry,
        enabled: false,
      );
      addTearDown(facade.dispose);
      await facade.followAdultReminders('a1', 'Ana');
      await facade.onNewToken('fcm-9');
      expect(registry.registered, isEmpty);
      final destination = await facade.destination(
        OmissionPushPayload.encode(
          OmissionPush(
            kind: OmissionPushKind.reinforcedReminder,
            olderAdultId: 'a1',
          ),
        ),
      );
      expect((destination! as OlderAdultHomeDestination).olderAdultName, 'Ana');
    });
  });

  group('notice text', () {
    test('is built in the language of the user from kind and medication', () {
      final es = lookupAppLocalizations(const Locale('es'));
      final en = lookupAppLocalizations(const Locale('en'));
      OmissionPush push(OmissionPushKind kind, [String? medication]) =>
          OmissionPush(
            kind: kind,
            olderAdultId: 'a1',
            medicationName: medication,
          );

      final reminder = OmissionNoticeText.of(
        es,
        push(OmissionPushKind.reinforcedReminder, 'Losartan'),
      );
      expect(reminder.title, 'Segundo recordatorio');
      expect(
        reminder.body,
        'Losartan sigue pendiente. Confírmala cuando la realices.',
      );

      final alert = OmissionNoticeText.of(
        en,
        push(OmissionPushKind.caregiverAlert, 'Metformina'),
      );
      expect(alert.title, 'Dose not confirmed');
      expect(alert.body, startsWith('Metformina was not confirmed in time.'));

      expect(
        OmissionNoticeText.of(
          es,
          push(OmissionPushKind.caregiverAlert, '  '),
        ).body,
        es.oeAlertText,
      );
      expect(
        OmissionNoticeText.of(
          en,
          push(OmissionPushKind.reinforcedReminder),
        ).body,
        en.oeReminderText,
      );
    });
  });

  group('follow widget', () {
    testWidgets('follows on appear and again only when the person changes', (
      tester,
    ) async {
      final followed = <String>[];
      Widget host(String key) => Directionality(
        textDirection: TextDirection.ltr,
        child: FollowOmissionPush(
          followKey: key,
          follow: () async => followed.add(key),
          child: const Text('screen'),
        ),
      );

      await tester.pumpWidget(host('a1'));
      expect(find.text('screen'), findsOneWidget);
      await tester.pumpWidget(host('a1'));
      expect(followed, ['a1']);
      await tester.pumpWidget(host('a2'));
      expect(followed, ['a1', 'a2']);
    });

    testWidgets('a failing follow never breaks the screen', (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: FollowOmissionPush(
            followKey: 'a1',
            follow: () async => throw StateError('storage unavailable'),
            child: const Text('screen'),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('screen'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

final class _HangingRegistry extends RecordingRegistry {
  int unregisterCalls = 0;

  @override
  Future<AppResult<void>> unregister({StoredSession? expectedSession}) {
    unregisterCalls++;
    return Future<AppResult<void>>.delayed(
      const Duration(days: 1),
      () => const AppSuccess(null),
    );
  }
}
