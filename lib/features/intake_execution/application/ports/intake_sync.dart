import '../readmodels/intake_sync_status.dart';

/// Delivers queued confirmations while the app is open.
abstract interface class IntakeSync {
  IntakeSyncStatus get status;
  Stream<IntakeSyncStatus> get changes;

  /// Attempts delivery now; concurrent requests share one serialized run.
  Future<void> request();

  /// Stops scheduled retries while the app is in the background.
  void suspend();
}
