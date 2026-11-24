import '../readmodels/push_destination.dart';

/// Lifecycle boundary consumed by the application host, without SDK dependencies.
abstract interface class OmissionDelivery {
  Stream<PushDestination> get destinations;
  Future<bool> start();
  Future<void> sessionChanged({required bool authenticated});
  Future<void> beforeSignOut();
  Future<void> dispose();
}
