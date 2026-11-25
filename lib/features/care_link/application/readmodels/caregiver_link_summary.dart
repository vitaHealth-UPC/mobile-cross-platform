/// One confirmed, consented relationship returned by the caregiver list contract.
/// This projection does not represent pending registrations or clinical data.
final class CaregiverLinkSummary {
  const CaregiverLinkSummary({
    required this.id,
    required this.olderAdultId,
    required this.fullName,
    required this.confirmedAt,
    this.adultSignedIn,
  });
  final String id;
  final String olderAdultId;
  final String fullName;
  final DateTime confirmedAt;

  /// Whether the adult holds a live session on some device; null when the
  /// server did not report it.
  final bool? adultSignedIn;

  @override
  String toString() => 'CaregiverLinkSummary[personalData=REDACTED]';
}
