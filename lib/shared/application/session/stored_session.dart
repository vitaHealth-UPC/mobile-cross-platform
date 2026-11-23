import 'session_owner.dart';

/// Secret-bearing transport state; never put it in a widget/Bloc state or log.
final class StoredSession {
  StoredSession({
    required this.accessToken,
    required this.expiresAt,
    required this.owner,
  }) {
    if (accessToken.isEmpty ||
        accessToken.length > 16384 ||
        RegExp(r'\s').hasMatch(accessToken)) {
      throw ArgumentError('Invalid session credential');
    }
  }

  /// Secret credential captured only for authorized transport requests.
  final String accessToken;
  final DateTime expiresAt;
  final SessionOwner owner;

  /// Expiry is exclusive: a credential expiring exactly at [now] is invalid.
  bool isValidAt(DateTime now) => expiresAt.isAfter(now);

  @override
  String toString() => 'StoredSession[REDACTED]';
}
