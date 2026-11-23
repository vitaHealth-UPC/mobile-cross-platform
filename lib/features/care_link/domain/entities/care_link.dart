import '../value_objects/linking_code.dart';

/// Relationship lifecycle independent of display labels or backend enum objects.
enum CareLinkStatus { pending, awaitingConsent, confirmed, revoked }

/// Relationship identity and optional temporary evidence, without session tokens.
final class CareLink {
  const CareLink({
    required this.id,
    required this.caregiverId,
    required this.olderAdultId,
    required this.status,
    this.code,
  });
  final String id;
  final String caregiverId;
  final String olderAdultId;
  final CareLinkStatus status;
  final LinkingCode? code;

  @override
  String toString() => 'CareLink[status=$status, personalData=REDACTED]';
}
