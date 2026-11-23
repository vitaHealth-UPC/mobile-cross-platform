/// Authorized profile projection; birth dates remain calendar dates, not instants.
final class OlderAdultProfile {
  const OlderAdultProfile({
    required this.id,
    required this.caregiverId,
    required this.fullName,
    required this.birthDate,
  });
  final String id;
  final String caregiverId;
  final String fullName;
  final DateTime birthDate;

  @override
  String toString() => 'OlderAdultProfile[personalData=REDACTED]';
}
