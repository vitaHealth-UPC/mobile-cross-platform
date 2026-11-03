/// One confirmed, consented relationship returned by the caregiver list contract.
/// This projection does not represent pending registrations or clinical data.
final class CaregiverLinkSummary {
  const CaregiverLinkSummary({
    required this.id,
    required this.olderAdultId,
    required this.fullName,
    required this.confirmedAt,
  });
  final String id;
  final String olderAdultId;
  final String fullName;
  final DateTime confirmedAt;

  @override
  String toString() => 'CaregiverLinkSummary[personalData=REDACTED]';
}
