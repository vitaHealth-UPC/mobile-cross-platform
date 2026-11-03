/// Normalized email value with conservative syntax and length validation.
/// Validation does not prove that a mailbox exists or belongs to the user.
final class EmailAddress {
  EmailAddress(String input) : value = input.trim().toLowerCase() {
    if (value.length > 254 ||
        !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value)) {
      throw ArgumentError('Invalid email');
    }
  }

  final String value;

  @override
  String toString() => 'EmailAddress[REDACTED]';
}
