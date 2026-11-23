import '../../../../shared/common/result/app_result.dart';
import '../../domain/entities/care_link.dart';
import '../ports/care_link_consent.dart';

/// Submits the adult's explicit decision for the session-bound relationship.
final class RegisterConsent {
  const RegisterConsent(this._consent);
  final CareLinkConsent _consent;
  Future<AppResult<CareLink>> call(bool accepted) => _consent.decide(accepted);
}
