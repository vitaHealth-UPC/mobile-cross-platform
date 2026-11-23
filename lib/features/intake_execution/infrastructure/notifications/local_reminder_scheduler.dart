import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../../../l10n/generated/app_localizations.dart';
import '../../application/ports/reminder_scheduler.dart';
import '../../application/readmodels/intake_reminder.dart';

/// [ReminderScheduler] on the platform's scheduled local notifications. The
/// alarms survive closing the app and are restored after a reboot.
final class LocalReminderScheduler implements ReminderScheduler {
  LocalReminderScheduler({
    required this._texts,
    FlutterLocalNotificationsPlugin? plugin,
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  /// Texts in the app language of the adult, read when reminders change.
  final Future<AppLocalizations> Function() _texts;
  final FlutterLocalNotificationsPlugin _plugin;
  final _opened = StreamController<String>.broadcast();
  Future<bool>? _ready;
  bool _launchTaken = false;

  static const _channel = 'intake_reminders';

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  /// Initializes once; false where the platform has no notifications.
  Future<bool> _initialize() => _ready ??= () async {
    try {
      final ok = await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
        onDidReceiveNotificationResponse: (response) {
          if (response.payload case final id? when id.isNotEmpty) {
            _opened.add(id);
          }
        },
      );
      return ok ?? false;
    } on Object {
      return false;
    }
  }();

  @override
  Stream<String> get opened => _opened.stream;

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
    await _plugin.cancelAllPendingNotifications();
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
        payload: reminder.intakeId,
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
      await _plugin.cancelAll();
    } on Object {
      // Nothing scheduled on this platform.
    }
  }

  @override
  Future<String?> takeLaunchDose() async {
    if (_launchTaken || !await _initialize()) return null;
    _launchTaken = true;
    try {
      final details = await _plugin.getNotificationAppLaunchDetails();
      if (details?.didNotificationLaunchApp != true) return null;
      final id = details?.notificationResponse?.payload;
      return id == null || id.isEmpty ? null : id;
    } on Object {
      return null;
    }
  }
}
