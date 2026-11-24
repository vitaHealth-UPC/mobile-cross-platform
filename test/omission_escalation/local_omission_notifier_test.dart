import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tata/features/omission_escalation/application/readmodels/omission_push_payload.dart';
import 'package:tata/features/omission_escalation/domain/value_objects/omission_push.dart';
import 'package:tata/features/omission_escalation/infrastructure/push/local_omission_notifier.dart';
import 'package:tata/l10n/generated/app_localizations_en.dart';
import 'package:tata/l10n/generated/app_localizations_es.dart';
import 'package:tata/shared/infrastructure/notifications/local_notification_platform.dart';

class _Plugin implements FlutterLocalNotificationsPlugin {
  String? title;
  String? body;
  String? payload;
  NotificationDetails? details;
  final active = <ActiveNotification>[];
  final cancelled = <int>[];
  Future<void> Function()? onShow;

  @override
  Future<bool?> initialize({
    required InitializationSettings settings,
    DidReceiveNotificationResponseCallback? onDidReceiveNotificationResponse,
    DidReceiveBackgroundNotificationResponseCallback?
    onDidReceiveBackgroundNotificationResponse,
  }) async => true;

  @override
  Future<void> show({
    required int id,
    String? title,
    String? body,
    NotificationDetails? notificationDetails,
    String? payload,
  }) async {
    this.title = title;
    this.body = body;
    this.payload = payload;
    details = notificationDetails;
    active.add(
      ActiveNotification(
        id: id,
        channelId: notificationDetails?.android?.channelId,
      ),
    );
    await onShow?.call();
  }

  @override
  Future<List<ActiveNotification>> getActiveNotifications() async =>
      List.of(active);

  @override
  Future<void> cancel({required int id, String? tag}) async {
    cancelled.add(id);
    active.removeWhere((notice) => notice.id == id);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

OmissionPush _push(OmissionPushKind kind) => OmissionPush(
  kind: kind,
  olderAdultId: 'adult-a',
  intakeId: 'dose-a',
  deliveryId: 'delivery-a',
  medicationName: 'Private medication',
);

void main() {
  test('Spanish notice keeps clinical text out of the visible body', () async {
    final plugin = _Plugin();
    final notifier = LocalOmissionNotifier(
      notifications: LocalNotificationPlatform(plugin: plugin),
      texts: () async => AppLocalizationsEs(),
      mayDisplay: (_) async => true,
    );
    final push = _push(OmissionPushKind.caregiverAlert);
    await notifier.show(push);
    expect(plugin.title, AppLocalizationsEs().oeAlertTitle);
    expect(plugin.body, AppLocalizationsEs().oeAlertText);
    expect(plugin.body, isNot(contains('Private medication')));
    expect(OmissionPushPayload.decode(plugin.payload)?.intakeId, 'dose-a');
    expect(plugin.details?.android?.visibility, NotificationVisibility.private);
    expect(plugin.details?.android?.icon, 'ic_omission_notification');
  });

  test(
    'English reminder uses the reminder channel and stable separate IDs',
    () async {
      final plugin = _Plugin();
      final notifier = LocalOmissionNotifier(
        notifications: LocalNotificationPlatform(plugin: plugin),
        texts: () async => AppLocalizationsEn(),
        mayDisplay: (_) async => true,
      );
      final push = _push(OmissionPushKind.reinforcedReminder);
      await notifier.show(push);
      expect(plugin.title, AppLocalizationsEn().oeReminderTitle);
      expect(
        plugin.details?.android?.channelId,
        LocalOmissionNotifier.reminderChannel,
      );
      expect(LocalOmissionNotifier.notificationId(push), lessThan(0));
      expect(
        LocalOmissionNotifier.notificationId(push),
        LocalOmissionNotifier.notificationId(_push(push.kind)),
      );
      expect(
        LocalOmissionNotifier.notificationId(push),
        isNot(
          LocalOmissionNotifier.notificationId(
            _push(OmissionPushKind.caregiverAlert),
          ),
        ),
      );
    },
  );

  test('logout while text loads prevents the display request', () async {
    final plugin = _Plugin();
    final text = Completer<AppLocalizationsEs>();
    var allowed = true;
    final notifier = LocalOmissionNotifier(
      notifications: LocalNotificationPlatform(plugin: plugin),
      texts: () => text.future,
      mayDisplay: (_) async => allowed,
    );
    final showing = notifier.show(_push(OmissionPushKind.caregiverAlert));
    await Future<void>.delayed(Duration.zero);
    allowed = false;
    text.complete(AppLocalizationsEs());
    await showing;
    expect(plugin.active, isEmpty);
  });

  test(
    'logout during platform display clears only omission channels',
    () async {
      final plugin = _Plugin()
        ..active.add(
          const ActiveNotification(id: 5, channelId: 'intake_reminders'),
        );
      var allowed = true;
      plugin.onShow = () async => allowed = false;
      final notifier = LocalOmissionNotifier(
        notifications: LocalNotificationPlatform(plugin: plugin),
        texts: () async => AppLocalizationsEs(),
        mayDisplay: (_) async => allowed,
      );
      final push = _push(OmissionPushKind.caregiverAlert);
      await notifier.show(push);
      expect(plugin.cancelled, [LocalOmissionNotifier.notificationId(push)]);
      expect(plugin.active.single.id, 5);
    },
  );
}
