import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Owns the plugin callback once for all notification consumers in this isolate.
/// Features retain ownership of channels, payloads and navigation authorization.
final class LocalNotificationPlatform {
  LocalNotificationPlatform({FlutterLocalNotificationsPlugin? plugin})
    : plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin plugin;
  final _opened = StreamController<String>.broadcast();
  Future<bool>? _ready;
  Future<String?>? _launch;

  Stream<String> get opened => _opened.stream;

  /// Initializes without requesting permission before a signed-in feature needs it.
  Future<bool> initialize() => _ready ??= () async {
    try {
      return await plugin.initialize(
            settings: const InitializationSettings(
              android: AndroidInitializationSettings('@mipmap/ic_launcher'),
              iOS: DarwinInitializationSettings(
                requestAlertPermission: false,
                requestBadgePermission: false,
                requestSoundPermission: false,
              ),
            ),
            onDidReceiveNotificationResponse: (response) {
              final payload = response.payload;
              if (payload != null && payload.isNotEmpty) _opened.add(payload);
            },
          ) ??
          false;
    } on Exception {
      return false;
    }
  }();

  /// A cached launch receipt lets each feature inspect only its own payload.
  Future<String?> launchPayload() => _launch ??= () async {
    if (!await initialize()) return null;
    final details = await plugin.getNotificationAppLaunchDetails();
    return details?.didNotificationLaunchApp == true
        ? details?.notificationResponse?.payload
        : null;
  }();

  /// Cancels only pending requests owned by the calling feature.
  Future<void> cancelPending(bool Function(String?) ownsPayload) async {
    for (final request in await plugin.pendingNotificationRequests()) {
      if (ownsPayload(request.payload)) await plugin.cancel(id: request.id);
    }
  }

  /// Android exposes channel identity; Darwin exposes the original payload.
  Future<void> cancelDisplayed({
    required String channel,
    required bool Function(String?) ownsPayload,
  }) async {
    for (final notice in await plugin.getActiveNotifications()) {
      final id = notice.id;
      if (id != null &&
          (notice.channelId == channel || ownsPayload(notice.payload))) {
        await plugin.cancel(id: id, tag: notice.tag);
      }
    }
  }
}
