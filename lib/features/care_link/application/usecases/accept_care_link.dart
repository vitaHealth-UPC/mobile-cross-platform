import '../../../../shared/common/result/app_result.dart';
import '../../domain/entities/care_link.dart';
import '../../domain/value_objects/care_link_invitation.dart';
import '../ports/care_link_consent.dart';

/// Validates a pasted invitation before consuming its one-use server evidence.
final class AcceptCareLink {
  const AcceptCareLink(this._consent);
  final CareLinkConsent _consent;
  Future<AppResult<CareLink>> call(String text) async {
    final CareLinkInvitation invitation;
    try {
      invitation = CareLinkInvitation.fromText(text);
    } on FormatException {
      return const AppFailure('INVALID_LINKING_CODE');
    }
    return _consent.accept(invitation);
  }
}
