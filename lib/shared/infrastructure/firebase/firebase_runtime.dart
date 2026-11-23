import 'package:firebase_core/firebase_core.dart';

/// Shares native Firebase initialization between authentication and messaging.
/// Failed initialization remains retryable after configuration becomes available.
abstract final class FirebaseRuntime {
  static Future<FirebaseApp>? _pending;

  static Future<FirebaseApp> initialize() async {
    if (Firebase.apps.isNotEmpty) return Firebase.app();
    final pending = _pending ??= Firebase.initializeApp();
    try {
      return await pending;
    } on Exception {
      if (identical(_pending, pending)) _pending = null;
      rethrow;
    }
  }
}
