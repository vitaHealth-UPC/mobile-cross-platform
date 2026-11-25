import '../../../application/readmodels/adult_access_redemption.dart';
import '../../../application/readmodels/caregiver_request.dart';
import '../../../domain/entities/care_link.dart';

/// Consent progress contains public relationship metadata, never session tokens.
final class ConsentState {
  const ConsentState({
    this.loading = false,
    this.link,
    this.errorCode,
    this.withdrawn = false,
    this.redemption,
    this.requests = const [],
    this.decided,
  });
  final bool loading;
  final CareLink? link;
  final String? errorCode;
  final bool withdrawn;

  /// Adult identified by an access code instead of a first invitation.
  final AdultAccessRedemption? redemption;

  /// Other caregivers waiting for the adult's decision.
  final List<CaregiverRequest> requests;

  /// Last decision taken on a request (true accepted, false declined).
  final bool? decided;
}
