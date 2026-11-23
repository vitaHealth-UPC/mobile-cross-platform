import '../../../../shared/application/session/session_owner.dart';
import '../../../../shared/application/session/stored_session.dart';
import '../remote/session_dto.dart';

/// Converts an untrusted credential to one unambiguous, unexpired actor session.
/// Throws [FormatException] or [ArgumentError] when identity or expiry is invalid.
StoredSession mapSession(SessionDto dto, DateTime now) {
  if ((dto.accountId == null) == (dto.olderAdultId == null)) {
    throw const FormatException('Ambiguous session owner');
  }
  // Require an offset: accepting a local timestamp changes expiration semantics.
  if (!RegExp(r'(Z|[+-]\d{2}:\d{2})$').hasMatch(dto.expiresAt)) {
    throw const FormatException('Missing expiry offset');
  }
  final session = StoredSession(
    accessToken: dto.accessToken,
    expiresAt: DateTime.parse(dto.expiresAt).toUtc(),
    owner: SessionOwner(
      dto.accountId ?? dto.olderAdultId!,
      dto.accountId != null ? SessionRole.caregiver : SessionRole.olderAdult,
      careLinkId: dto.careLinkId,
    ),
  );
  if (!session.isValidAt(now)) throw const FormatException('Expired session');
  return session;
}
