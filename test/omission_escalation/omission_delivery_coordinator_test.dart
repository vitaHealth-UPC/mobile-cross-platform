import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tata/features/omission_escalation/application/policies/omission_push_access_policy.dart';
import 'package:tata/features/omission_escalation/application/ports/omission_message_source.dart';
import 'package:tata/features/omission_escalation/application/readmodels/omission_push_payload.dart';
import 'package:tata/features/omission_escalation/application/readmodels/push_destination.dart';
import 'package:tata/features/omission_escalation/application/services/omission_delivery_coordinator.dart';
import 'package:tata/features/omission_escalation/application/services/omission_notification_session_cleanup.dart';
import 'package:tata/features/omission_escalation/application/services/omission_push_facade.dart';
import 'package:tata/features/omission_escalation/application/services/push_device_registration_coordinator.dart';
import 'package:tata/features/omission_escalation/application/usecases/follow_caregiver_alerts.dart';
import 'package:tata/features/omission_escalation/application/usecases/follow_dose_reminders.dart';
import 'package:tata/features/omission_escalation/application/usecases/handle_incoming_omission_push.dart';
import 'package:tata/features/omission_escalation/application/usecases/resolve_push_destination.dart';
import 'package:tata/features/omission_escalation/domain/value_objects/omission_push.dart';
import 'package:tata/shared/application/session/session_owner.dart';
import 'package:tata/shared/application/session/stored_session.dart';
import 'package:tata/shared/common/result/app_result.dart';

import '../support/memory_session_store.dart';
import 'omission_fakes.dart';

class _Source implements OmissionMessageSource {
  bool available = true;
  String? initial;
  final messages = StreamController<OmissionPush>.broadcast();
  final taps = StreamController<String>.broadcast();
  @override
  Future<bool> initialize() async => available;
  @override
  Stream<OmissionPush> get received => messages.stream;
  @override
  Stream<String> get opened => taps.stream;
  @override
  Future<String?> initialPayload() async => initial;
}

StoredSession _session(String id) => StoredSession(
  accessToken: 'credential-$id',
  expiresAt: DateTime.now().add(const Duration(hours: 1)),
  owner: SessionOwner(id, SessionRole.olderAdult, careLinkId: 'link-$id'),
);

OmissionPush _push([String adult = 'adult-a']) => OmissionPush(
  kind: OmissionPushKind.reinforcedReminder,
  olderAdultId: adult,
  intakeId: 'dose-a',
);

void main() {
  late _Source source;
  late MemorySessionStore store;
  late RecordingNotifier notifier;
  late RecordingRegistry registry;
  late StreamController<String> tokens;
  late StreamController<String> local;
  late OmissionDeliveryCoordinator coordinator;
  late List<PushDestination> opened;
  String? localInitial;
  late StreamSubscription<PushDestination> subscription;

  setUp(() {
    localInitial = null;
    source = _Source();
    store = MemorySessionStore(_session('adult-a'));
    notifier = RecordingNotifier();
    registry = RecordingRegistry();
    tokens = StreamController<String>.broadcast();
    local = StreamController<String>.broadcast();
    final targets = MemoryPushTargets();
    final policy = OmissionPushAccessPolicy(sessions: store, targets: targets);
    final facade = OmissionPushFacade(
      policy: policy,
      followCaregiver: FollowCaregiverAlerts(targets),
      followReminders: FollowDoseReminders(targets),
      resolve: ResolvePushDestination(targets),
      handle: HandleIncomingOmissionPush(policy, notifier),
      registration: PushDeviceRegistrationCoordinator(
        sessions: store,
        tokens: ScriptedTokenSource([const AppSuccess('address-a')]),
        registry: registry,
        retryDelays: const [],
      ),
      cleanup: OmissionNotificationSessionCleanup(notifier: notifier),
      registrationEnabled: true,
    );
    coordinator = OmissionDeliveryCoordinator(
      source: source,
      facade: facade,
      sessions: store,
      rotatedTokens: tokens.stream,
      localTaps: local.stream,
      initialLocalPayload: () async => localInitial,
    );
    opened = [];
    subscription = coordinator.destinations.listen(opened.add);
  });

  tearDown(() async {
    await subscription.cancel();
    await coordinator.dispose();
    await source.messages.close();
    await source.taps.close();
    await tokens.close();
    await local.close();
  });

  Future<void> drain() => Future<void>.delayed(Duration.zero);

  test(
    'cold-start tap waits for restored access and opens the exact dose',
    () async {
      source.initial = OmissionPushPayload.encode(_push());
      expect(await coordinator.start(), isTrue);
      expect(opened, isEmpty);
      local.add('intake:dose-from-another-feature');
      await drain();
      await coordinator.sessionChanged(authenticated: true);
      await drain();
      expect((opened.single as OlderAdultDoseDestination).intakeId, 'dose-a');
      expect(registry.registered.single.session?.owner.id, 'adult-a');
    },
  );

  test('messages for a different recipient never reach the notifier', () async {
    await coordinator.start();
    source.messages.add(_push('adult-b'));
    source.messages.add(_push());
    await drain();
    expect(notifier.shown, hasLength(1));
    expect(notifier.shown.single.olderAdultId, 'adult-a');
  });

  test(
    'local cold-start receipt remains usable without the remote SDK',
    () async {
      source.available = false;
      localInitial = OmissionPushPayload.encode(_push());
      expect(await coordinator.start(), isFalse);
      await coordinator.sessionChanged(authenticated: true);
      await drain();
      expect((opened.single as OlderAdultDoseDestination).intakeId, 'dose-a');
      expect(registry.registered, isEmpty);
    },
  );

  test(
    'queued navigation is discarded when the session owner changes',
    () async {
      source.initial = OmissionPushPayload.encode(_push());
      await coordinator.start();
      await coordinator.sessionChanged(authenticated: false);
      await store.replace(
        _session('adult-b'),
        expectedGeneration: store.generation,
      );
      await coordinator.sessionChanged(authenticated: true);
      await drain();
      expect(opened, isEmpty);
    },
  );

  test(
    'missing SDK keeps registration off while local taps remain authorized',
    () async {
      source.available = false;
      expect(await coordinator.start(), isFalse);
      await coordinator.sessionChanged(authenticated: true);
      local.add(OmissionPushPayload.encode(_push()));
      await drain();
      expect(opened, hasLength(1));
      expect(registry.registered, isEmpty);
    },
  );

  test(
    'sign-out removes the device with its credential and blocks delayed taps',
    () async {
      await coordinator.start();
      await coordinator.sessionChanged(authenticated: true);
      await drain();
      tokens.add('rotated-address');
      await drain();
      expect(registry.registered.last.token, 'rotated-address');
      await coordinator.beforeSignOut();
      expect(registry.unregistered.single?.accessToken, 'credential-adult-a');
      await store.replace(null, expectedGeneration: store.generation);
      await coordinator.sessionChanged(authenticated: false);
      local.add(OmissionPushPayload.encode(_push()));
      source.messages.add(_push());
      await drain();
      expect(opened, isEmpty);
      expect(notifier.shown, isEmpty);
      await store.replace(
        _session('adult-a'),
        expectedGeneration: store.generation,
      );
      await coordinator.sessionChanged(authenticated: true);
      await drain();
      expect(opened, isEmpty);
    },
  );
}
