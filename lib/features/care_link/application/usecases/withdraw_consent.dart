import '../../../../shared/common/result/app_result.dart';
import '../ports/care_link_consent.dart';

/// Withdraws the authenticated adult's relationship without accepting an actor ID.
final class WithdrawConsent {
  const WithdrawConsent(this._consent);
  final CareLinkConsent _consent;
  Future<AppResult<void>> call() => _consent.withdraw();
}
