/// Another caregiver waiting for the adult to accept them.
final class CaregiverRequest {
  const CaregiverRequest({required this.careLinkId, this.caregiverName});
  final String careLinkId;
  final String? caregiverName;

  @override
  String toString() => 'CaregiverRequest[personalData=REDACTED]';
}
