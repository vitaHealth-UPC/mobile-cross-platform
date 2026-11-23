import '../../../../shared/common/result/app_result.dart';
import '../../domain/entities/care_link.dart';
import '../../domain/value_objects/care_link_invitation.dart';

/// Exchanges invitation evidence for restricted access and an explicit adult decision.
abstract interface class CareLinkConsent {
  /// Requires an anonymous local session; stores only LINK_SETUP on success.
  Future<AppResult<CareLink>> accept(CareLinkInvitation invitation);

  /// Reads the relationship bound to the captured restricted credential.
  Future<AppResult<CareLink>> pending();

  /// Approval replaces restricted access with adult access; rejection clears it.
  Future<AppResult<CareLink>> decide(bool accepted);

  /// Withdraws only the confirmed relationship in the full adult session scope.
  /// Local access is cleared after the server acknowledges revocation.
  Future<AppResult<void>> withdraw();
}
