import '../../../../shared/application/session/stored_session.dart';
import '../../domain/value_objects/omission_push.dart';
import '../policies/omission_push_access_policy.dart';
import '../readmodels/omission_push_payload.dart';
import '../readmodels/push_destination.dart';
import '../usecases/omission_usecases.dart';
import 'omission_notification_session_cleanup.dart';
import 'push_device_registration_coordinator.dart';

/// The only entry the application shell uses to reach Omission & Escalation: it never builds
/// push repositories or applies the recipient policy on this context's behalf.
final class OmissionPushFacade {
  OmissionPushFacade({
    required this._policy,
    required this._followCaregiver,
    required this._followReminders,
    required this._resolve,
    required this._handle,
    required this._registration,
    required this._cleanup,
    required this.registrationEnabled,
  });

  final OmissionPushAccessPolicy _policy;
  final FollowCaregiverAlerts _followCaregiver;
  final FollowDoseReminders _followReminders;
  final ResolvePushDestination _resolve;
  final HandleIncomingOmissionPush _handle;
  final PushDeviceRegistrationCoordinator _registration;
  final OmissionNotificationSessionCleanup _cleanup;

  /// False in a build without a push provider: nothing is registered with the backend.
  final bool registrationEnabled;

  /// A caregiver looks at the follow-up of [olderAdultId]; alerts of that person may open it.
  Future<void> followCaregiver(String caregiverId, String olderAdultId) async {
    await _followCaregiver(
      caregiverId: caregiverId,
      olderAdultId: olderAdultId,
    );
    await synchronizeDevice();
  }

  /// An older adult is signed in; their reinforced reminders may open the intake.
  Future<void> followAdultReminders(
    String olderAdultId,
    String olderAdultName,
  ) async {
    await _followReminders(
      olderAdultId: olderAdultId,
      olderAdultName: olderAdultName,
    );
    await synchronizeDevice();
  }

  /// Registers this installation for the signed-in owner, if push is configured.
  Future<void> synchronizeDevice() async {
    if (registrationEnabled) await _registration.synchronize();
  }

  /// Push SDK token rotation.
  Future<void> onNewToken(String token) async {
    if (registrationEnabled) await _registration.onNewToken(token);
  }

  /// Removes the registration while the credential still exists.
  Future<void> beforeSignOut() => _registration.beforeSignOut();

  /// A message reached the device: it is shown only to its recipient.
  Future<bool> onPush(OmissionPush push) => _handle(push);

  /// Whether [push] may be displayed under the session in force.
  Future<bool> canDisplay(OmissionPush push) => _policy.allows(push);

  /// Resolves a tap payload to a destination the signed-in owner may open, or null.
  Future<PushDestination?> destination(String? payload) async {
    final query = OmissionPushPayload.decode(payload);
    if (query == null) return null;
    final destination = await _resolve(query);
    if (destination == null) return null;
    return await _policy.allowsDestination(destination) ? destination : null;
  }

  Future<bool> canOpen(PushDestination destination) =>
      _policy.allowsDestination(destination);

  /// Clears displayed notices when the recipient session stops applying.
  Future<void> observeSession(StoredSession? session) =>
      _cleanup.observe(session);

  void dispose() => _cleanup.dispose();
}
