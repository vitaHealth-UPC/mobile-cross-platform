import '../../../../shared/common/result/app_result.dart';
import '../../domain/entities/care_link.dart';
import '../../domain/value_objects/care_link_invitation.dart';
import '../readmodels/adult_access_redemption.dart';
import '../readmodels/caregiver_request.dart';

/// Exchanges invitation evidence for restricted access and an explicit adult decision.
abstract interface class CareLinkConsent {
  /// Requires an anonymous local session; stores only LINK_SETUP on success.
  Future<AppResult<CareLink>> accept(CareLinkInvitation invitation);

  /// Redeems a caregiver-issued access code on this device. Without a PIN the
  /// adult session is stored so the PIN can be created; with one, nothing is
  /// stored and the device must sign in with it.
  Future<AppResult<AdultAccessRedemption>> redeem(String code);

  /// Other caregivers waiting for the signed-in adult's decision.
  Future<AppResult<List<CaregiverRequest>>> caregiverRequests();

  /// The signed-in adult accepts or rejects another caregiver.
  Future<AppResult<void>> decideCaregiverRequest(
    String careLinkId,
    bool accepted,
  );

  /// Removes the adult's account; local access is cleared once acknowledged.
  Future<AppResult<void>> removeAccount();

  /// Reads the relationship bound to the captured restricted credential.
  Future<AppResult<CareLink>> pending();

  /// Approval replaces restricted access with adult access; rejection clears it.
  Future<AppResult<CareLink>> decide(bool accepted);

  /// Withdraws only the confirmed relationship in the full adult session scope.
  /// Local access is cleared after the server acknowledges revocation.
  Future<AppResult<void>> withdraw();
}
