/// Temporary linking evidence; diagnostic output never reveals the code.
final class LinkingCode {
  LinkingCode(this.value, this.expiresAt) {
    if (value.isEmpty || value != value.trim() || value.length > 32) {
      throw ArgumentError('Invalid linking code');
    }
  }
  final String value;
  final DateTime expiresAt;

  /// Expiration is exclusive, matching the server's challenge lifetime.
  bool isValidAt(DateTime now) => now.isBefore(expiresAt);

  @override
  String toString() => 'LinkingCode[REDACTED]';
}
