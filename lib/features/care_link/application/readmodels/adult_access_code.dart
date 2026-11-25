/// Single-use code a caregiver shares so the adult can sign in on a new device.
final class AdultAccessCode {
  const AdultAccessCode({required this.code, required this.expiresAt});
  final String code;
  final DateTime expiresAt;

  @override
  String toString() => 'AdultAccessCode[REDACTED]';
}
