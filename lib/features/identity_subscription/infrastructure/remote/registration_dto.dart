import 'session_dto.dart';

/// Untrusted account projection; no diagnostic output contains personal data.
final class RegistrationDto {
  RegistrationDto._(this.id, this.email, this.status, this.session);
  final String id;
  final String email;
  final String status;
  final SessionDto? session;

  factory RegistrationDto.fromJson(Object? body, {required bool verified}) {
    if (body is! Map<String, dynamic>) throw const FormatException();
    final id = body['id'];
    final email = body['email'];
    final status = body['status'];
    if (id is! String ||
        id.trim().isEmpty ||
        id != id.trim() ||
        email is! String ||
        status != (verified ? 'ACTIVE' : 'PENDING_VERIFICATION')) {
      throw const FormatException();
    }
    if (!verified &&
        (body['accessToken'] != null || body['expiresAt'] != null)) {
      throw const FormatException('Pending account cannot issue a credential');
    }
    return RegistrationDto._(
      id,
      email,
      status,
      verified
          ? SessionDto.fromJson({
              'accountId': id,
              'accessToken': body['accessToken'],
              'expiresAt': body['expiresAt'],
            })
          : null,
    );
  }

  @override
  String toString() => 'RegistrationDto[REDACTED]';
}
