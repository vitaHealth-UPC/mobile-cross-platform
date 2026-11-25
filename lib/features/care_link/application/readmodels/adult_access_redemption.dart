/// Adult identified on this device by a caregiver-issued access code. When
/// [pinRegistered] the device still has to sign in with the adult's PIN.
final class AdultAccessRedemption {
  const AdultAccessRedemption({
    required this.olderAdultId,
    required this.pinRegistered,
    this.olderAdultName,
  });
  final String olderAdultId;
  final String? olderAdultName;
  final bool pinRegistered;

  @override
  String toString() => 'AdultAccessRedemption[personalData=REDACTED]';
}
