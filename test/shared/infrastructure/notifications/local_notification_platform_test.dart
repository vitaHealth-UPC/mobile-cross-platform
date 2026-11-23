import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tata/features/intake_execution/infrastructure/notifications/local_reminder_scheduler.dart';
import 'package:tata/l10n/generated/app_localizations_es.dart';
import 'package:tata/shared/infrastructure/notifications/local_notification_platform.dart';

class _Plugin implements FlutterLocalNotificationsPlugin {
  int initializations = 0;
  DidReceiveNotificationResponseCallback? tapped;
  final cancelled = <int>[];
  final pending = <PendingNotificationRequest>[];
  final active = <ActiveNotification>[];

  @override
  Future<bool?> initialize({
    required InitializationSettings settings,
    DidReceiveNotificationResponseCallback? onDidReceiveNotificationResponse,
    DidReceiveBackgroundNotificationResponseCallback?
    onDidReceiveBackgroundNotificationResponse,
  }) async {
    initializations++;
    tapped = onDidReceiveNotificationResponse;
    return true;
  }

  @override
  Future<List<PendingNotificationRequest>>
  pendingNotificationRequests() async => pending;

  @override
  Future<List<ActiveNotification>> getActiveNotifications() async => active;

  @override
  Future<void> cancel({required int id, String? tag}) async =>
      cancelled.add(id);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test(
    'initialization keeps one callback shared by independent consumers',
    () async {
      final plugin = _Plugin();
      final platform = LocalNotificationPlatform(plugin: plugin);
      final first = <String>[];
      final second = <String>[];
      final a = platform.opened.listen(first.add);
      final b = platform.opened.listen(second.add);
      await Future.wait([platform.initialize(), platform.initialize()]);
      plugin.tapped!(
        const NotificationResponse(
          notificationResponseType:
              NotificationResponseType.selectedNotification,
          payload: 'omission:example',
        ),
      );
      await Future<void>.delayed(Duration.zero);
      expect(plugin.initializations, 1);
      expect(first, ['omission:example']);
      expect(second, first);
      await a.cancel();
      await b.cancel();
    },
  );

  test(
    'intake cleanup preserves pending and displayed omission notices',
    () async {
      final plugin = _Plugin()
        ..pending.addAll(const [
          PendingNotificationRequest(1, null, null, 'intake:dose-a'),
          PendingNotificationRequest(
            2,
            null,
            null,
            '{"kind":"CAREGIVER_ALERT"}',
          ),
          PendingNotificationRequest(3, null, null, 'unrelated'),
        ])
        ..active.addAll(const [
          ActiveNotification(id: 4, channelId: 'intake_reminders'),
          ActiveNotification(id: 5, channelId: 'omission_alerts'),
          ActiveNotification(id: 6, payload: 'intake:dose-b'),
        ]);
      final scheduler = LocalReminderScheduler(
        texts: () async => AppLocalizationsEs(),
        notifications: LocalNotificationPlatform(plugin: plugin),
      );
      await scheduler.cancelAll();
      expect(plugin.cancelled, [1, 4, 6]);
    },
  );

  test(
    'intake taps accept their namespace and old UUIDs, never push JSON',
    () async {
      final plugin = _Plugin();
      final platform = LocalNotificationPlatform(plugin: plugin);
      final scheduler = LocalReminderScheduler(
        texts: () async => AppLocalizationsEs(),
        notifications: platform,
      );
      final opened = <String>[];
      final subscription = scheduler.opened.listen(opened.add);
      await platform.initialize();
      for (final payload in [
        'intake:dose-a',
        '{"kind":"CAREGIVER_ALERT"}',
        'e2a1424c-456a-4c33-bfd9-987221f18a1a',
        'intake:',
      ]) {
        plugin.tapped!(
          NotificationResponse(
            notificationResponseType:
                NotificationResponseType.selectedNotification,
            payload: payload,
          ),
        );
      }
      await Future<void>.delayed(Duration.zero);
      expect(opened, ['dose-a', 'e2a1424c-456a-4c33-bfd9-987221f18a1a']);
      await subscription.cancel();
    },
  );
}
