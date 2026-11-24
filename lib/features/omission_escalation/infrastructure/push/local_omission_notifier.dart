import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/infrastructure/notifications/local_notification_platform.dart';
import '../../application/ports/omission_notifier.dart';
import '../../application/readmodels/omission_push_payload.dart';
import '../../domain/value_objects/omission_push.dart';

/// Displays localized omission notices after recipient authorization is rechecked.
/// The lock-screen body is generic; clinical references stay in the tap payload.
final class LocalOmissionNotifier implements OmissionNotifier {
  LocalOmissionNotifier({
    required this._notifications,
    required this._texts,
    required this._mayDisplay,
  });

  static const reminderChannel = 'omission_reminders';
  static const alertChannel = 'omission_alerts';
  final LocalNotificationPlatform _notifications;
  final Future<AppLocalizations> Function() _texts;
  final Future<bool> Function(OmissionPush) _mayDisplay;
  Future<void> _tail = Future<void>.value();

  /// Uses negative IDs, separate from the nonnegative scheduled-dose identifiers.
  static int notificationId(OmissionPush push) {
    final key =
        '${push.kind.wireName}:${push.olderAdultId}:'
        '${push.deliveryId ?? push.intakeId ?? "legacy"}';
    var hash = 0x811c9dc5;
    for (final unit in key.codeUnits) {
      hash = ((hash ^ unit) * 0x01000193) & 0x3fffffff;
    }
    return -(hash + 1);
  }

  @override
  Future<void> show(OmissionPush push) => _serial(() async {
    if (!await _notifications.initialize() || !await _mayDisplay(push)) return;
    final text = await _texts();
    if (!await _mayDisplay(push)) return;
    final reminder = push.kind == OmissionPushKind.reinforcedReminder;
    await _notifications.plugin.show(
      id: notificationId(push),
      title: reminder ? text.oeReminderTitle : text.oeAlertTitle,
      body: reminder ? text.oeReminderText : text.oeAlertText,
      payload: OmissionPushPayload.encode(push),
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          reminder ? reminderChannel : alertChannel,
          reminder ? text.oeChannelReminders : text.oeChannelAlerts,
          channelDescription: reminder
              ? text.oeChannelRemindersDescription
              : text.oeChannelAlertsDescription,
          icon: 'ic_omission_notification',
          importance: Importance.high,
          priority: Priority.high,
          visibility: NotificationVisibility.private,
          onlyAlertOnce: true,
          category: AndroidNotificationCategory.reminder,
        ),
        iOS: DarwinNotificationDetails(
          threadIdentifier: reminder ? reminderChannel : alertChannel,
        ),
      ),
    );
    // Logout can finish while the platform is accepting the notice.
    if (!await _mayDisplay(push)) await _clearOwn();
  });

  @override
  Future<void> clearDisplayed() => _serial(_clearOwn);

  Future<void> _clearOwn() async {
    if (!await _notifications.initialize()) return;
    for (final channel in [reminderChannel, alertChannel]) {
      await _notifications.cancelDisplayed(
        channel: channel,
        ownsPayload: (payload) => OmissionPushPayload.decode(payload) != null,
      );
    }
  }

  Future<void> _serial(Future<void> Function() operation) {
    final result = _tail.then((_) => operation());
    _tail = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }
}
