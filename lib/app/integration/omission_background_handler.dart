import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../features/accessibility_preferences/infrastructure/local/shared_preferences_stores.dart';
import '../../features/omission_escalation/application/policies/omission_push_access_policy.dart';
import '../../features/omission_escalation/infrastructure/local/push_local_stores.dart';
import '../../features/omission_escalation/infrastructure/push/firebase_omission_message_source.dart';
import '../../features/omission_escalation/infrastructure/push/local_omission_notifier.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/infrastructure/notifications/local_notification_platform.dart';
import '../../shared/infrastructure/security/secure_session_store.dart';

/// Allows Android builds to exercise background delivery against configured Firebase.
bool get omissionPushEnabled =>
    !kIsWeb &&
    defaultTargetPlatform == TargetPlatform.android &&
    const bool.fromEnvironment('TATA_ENABLE_OMISSION_PUSH');

void registerOmissionBackgroundHandler() {
  if (omissionPushEnabled) {
    FirebaseMessaging.onBackgroundMessage(receiveOmissionInBackground);
  }
}

/// Runs in the messaging isolate using only the dependencies needed for display.
@pragma('vm:entry-point')
Future<void> receiveOmissionInBackground(RemoteMessage message) async {
  if (!omissionPushEnabled) return;
  final push = FirebaseOmissionMessageSource.decode(message);
  if (push == null) return;
  WidgetsFlutterBinding.ensureInitialized();

  SecureSessionStore sessions() => SecureSessionStore(
    storage: const FlutterSecureStorage(),
    clock: DateTime.now,
  );

  final notifier = LocalOmissionNotifier(
    notifications: LocalNotificationPlatform(),
    texts: () async {
      final store = sessions();
      await store.initialize();
      final owner = store.current?.owner;
      if (owner == null) return lookupAppLocalizations(const Locale('es'));
      final language = await SharedPreferencesLanguageStore()
          .watch(owner.id)
          .first
          .timeout(const Duration(seconds: 2));
      return lookupAppLocalizations(Locale(language.tag));
    },
    mayDisplay: (candidate) => OmissionPushAccessPolicy(
      sessions: sessions(),
      targets: SharedPreferencesPushTargetStore(),
    ).allows(candidate),
  );
  try {
    await notifier.show(push);
  } on Exception {
    // Storage or platform failure leaves the notice undisplayed.
  }
}
