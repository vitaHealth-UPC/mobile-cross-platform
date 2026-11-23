/// Untrusted response fields; mapping verifies identity and credential semantics.
final class SessionDto {
  const SessionDto({
    required this.accountId,
    required this.olderAdultId,
    required this.accessToken,
    required this.expiresAt,
    this.careLinkId,
  });
  final String? accountId;
  final String? olderAdultId;
  final String accessToken;
  final String expiresAt;
  final String? careLinkId;

  factory SessionDto.fromJson(Object? body) {
    if (body is! Map<String, dynamic>) throw const FormatException();
    final token = body['accessToken'];
    final expires = body['expiresAt'];
    final account = body['accountId'];
    final adult = body['olderAdultId'];
    final link = body['careLinkId'];
    if (token is! String ||
        expires is! String ||
        (account != null && account is! String) ||
        (adult != null && adult is! String) ||
        (link != null && link is! String)) {
      throw const FormatException();
    }
    return SessionDto(
      accountId: account as String?,
      olderAdultId: adult as String?,
      accessToken: token,
      expiresAt: expires,
      careLinkId: link as String?,
    );
  }

  @override
  String toString() => 'SessionDto[REDACTED]';
}
