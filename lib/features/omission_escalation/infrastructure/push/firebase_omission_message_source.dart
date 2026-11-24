import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../../../../shared/infrastructure/firebase/firebase_runtime.dart';
import '../../application/ports/omission_message_source.dart';
import '../../application/readmodels/omission_push_payload.dart';
import '../../domain/value_objects/omission_push.dart';
import 'omission_push_data_mapper.dart';

/// Maps data-only FCM deliveries and remote taps to the versioned Tata contract.
/// Notification title/body and legacy topics cannot authorize a clinical event.
final class FirebaseOmissionMessageSource implements OmissionMessageSource {
  FirebaseOmissionMessageSource({
    Future<FirebaseMessaging> Function()? messaging,
    Stream<RemoteMessage>? foreground,
    Stream<RemoteMessage>? opened,
    bool? supported,
  }) : _messaging = messaging ?? _nativeMessaging,
       _foreground = foreground ?? FirebaseMessaging.onMessage,
       _opened = opened ?? FirebaseMessaging.onMessageOpenedApp,
       _supported =
           supported ??
           (!kIsWeb &&
               (defaultTargetPlatform == TargetPlatform.android ||
                   defaultTargetPlatform == TargetPlatform.iOS));

  final Future<FirebaseMessaging> Function() _messaging;
  final Stream<RemoteMessage> _foreground;
  final Stream<RemoteMessage> _opened;
  final bool _supported;
  Future<bool>? _ready;
  FirebaseMessaging? _sdk;

  static Future<FirebaseMessaging> _nativeMessaging() async {
    await FirebaseRuntime.initialize();
    return FirebaseMessaging.instance;
  }

  @override
  Future<bool> initialize() => _ready ??= () async {
    if (!_supported) return false;
    try {
      _sdk = await _messaging();
      return true;
    } on Exception {
      return false;
    }
  }();

  /// Rejects nonstring data fields rather than coercing malformed payloads.
  static OmissionPush? decode(RemoteMessage message) {
    final data = <String, String>{};
    for (final entry in message.data.entries) {
      if (entry.value is! String) return null;
      data[entry.key] = entry.value as String;
    }
    return omissionPushFromData(data);
  }

  @override
  Stream<OmissionPush> get received => _foreground
      .map(decode)
      .where((push) => push != null)
      .cast<OmissionPush>();

  @override
  Stream<String> get opened => _opened
      .map(decode)
      .where((push) => push != null)
      .cast<OmissionPush>()
      .map(OmissionPushPayload.encode);

  @override
  Future<String?> initialPayload() async {
    if (!await initialize()) return null;
    try {
      final message = await _sdk!.getInitialMessage();
      final push = message == null ? null : decode(message);
      return push == null ? null : OmissionPushPayload.encode(push);
    } on Exception {
      return null;
    }
  }
}
