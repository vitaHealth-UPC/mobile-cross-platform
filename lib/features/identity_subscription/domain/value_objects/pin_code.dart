/// Four ASCII digits, the same format the backend enforces for enrollment and access.
/// The value is a secret: it never reaches logs, presentation state or storage.
final class PinCode {
  PinCode(this.value) {
    if (!RegExp(r'^[0-9]{4}$').hasMatch(value)) {
      throw ArgumentError('Invalid PIN');
    }
  }

  static const length = 4;

  final String value;

  @override
  String toString() => 'PinCode[REDACTED]';
}
