import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/infrastructure/notifications/local_notification_platform.dart';
import '../../application/ports/reminder_scheduler.dart';
import '../../application/readmodels/intake_reminder.dart';

/// [ReminderScheduler] on the platform's scheduled local notifications. The
/// alarms survive closing the app and are restored after a reboot.
final class LocalReminderScheduler implements ReminderScheduler {
  LocalReminderScheduler({
    required this._texts,
    FlutterLocalNotificationsPlugin? plugin,
    LocalNotificationPlatform? notifications,
  }) : _notifications =
           notifications ?? LocalNotificationPlatform(plugin: plugin);

  /// Texts in the app language of the adult, read when reminders change.
  final Future<AppLocalizations> Function() _texts;
  final LocalNotificationPlatform _notifications;
  FlutterLocalNotificationsPlugin get _plugin => _notifications.plugin;
  bool _launchTaken = false;

  static const _channel = 'intake_reminders';

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  static const _prefix = 'intake:';
  static final _legacyId = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  static String? _dose(String? payload) {
    if (payload == null) return null;
    if (payload.startsWith(_prefix)) {
      final id = payload.substring(_prefix.length);
      return id.isEmpty ? null : id;
    }
    return _legacyId.hasMatch(payload) ? payload : null;
  }

  Future<bool> _initialize() => _notifications.initialize();

  @override
  Stream<String> get opened =>
      _notifications.opened.map(_dose).where((id) => id != null).cast<String>();

  @override
  Future<void> prepare() async {
    if (!await _initialize()) return;
    try {
      final text = await _texts();
      await _android?.createNotificationChannel(
        AndroidNotificationChannel(
          _channel,
          text.reminderChannelName,
          description: text.reminderChannelDescription,
          importance: Importance.high,
        ),
      );
      await _android?.requestNotificationsPermission();
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        await _plugin
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >()
            ?.requestPermissions(alert: true, sound: true);
      }
    } on Object {
      // Without permission the reminders inside the app still work.
    }
  }

  @override
  Future<void> replaceAll(List<IntakeReminder> reminders) async {
    if (!await _initialize()) return;
    final text = await _texts();
    await _notifications.cancelPending((payload) => _dose(payload) != null);
    // Exact alarms keep the dose time; without that permission Android may
    // delay an inexact one by a few minutes.
    final exact = await _android?.canScheduleExactNotifications() ?? true;
    final mode = exact
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;
    for (final reminder in reminders) {
      final due = reminder.kind == ReminderKind.due;
      await _plugin.zonedSchedule(
        id: reminder.notificationId,
        scheduledDate: tz.TZDateTime.from(reminder.at, tz.UTC),
        title: due ? text.homeDueTitle : text.homeReinforcedTitle,
        body: due
            ? text.reminderDueBody(reminder.medicationName, reminder.dose)
            : text.reminderReinforcedBody(reminder.medicationName),
        payload: '$_prefix${reminder.intakeId}',
        androidScheduleMode: mode,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _channel,
            text.reminderChannelName,
            channelDescription: text.reminderChannelDescription,
            importance: Importance.high,
            priority: Priority.high,
            category: AndroidNotificationCategory.reminder,
          ),
          iOS: const DarwinNotificationDetails(),
        ),
      );
    }
  }

  @override
  Future<void> cancelAll() async {
    if (!await _initialize()) return;
    try {
      await _notifications.cancelPending((payload) => _dose(payload) != null);
      await _notifications.cancelDisplayed(
        channel: _channel,
        ownsPayload: (payload) => _dose(payload) != null,
      );
    } on Object {
      // Nothing scheduled on this platform.
    }
  }

  @override
  Future<String?> takeLaunchDose() async {
    if (_launchTaken || !await _initialize()) return null;
    _launchTaken = true;
    try {
      return _dose(await _notifications.launchPayload());
    } on Object {
      return null;
    }
  }
}
