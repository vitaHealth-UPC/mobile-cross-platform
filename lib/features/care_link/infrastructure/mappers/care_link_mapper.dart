import '../../../../shared/application/session/session_owner.dart';
import '../../../../shared/application/session/stored_session.dart';
import '../../application/readmodels/caregiver_link_summary.dart';
import '../../application/readmodels/older_adult_profile.dart';
import '../../domain/entities/care_link.dart';
import '../../domain/value_objects/linking_code.dart';

/// Strict projections of caregiver setup receipts, rejecting invented defaults.
abstract final class CareLinkMapper {
  /// Validates evidence consumed for consent without granting clinical access.
  static CareLink awaiting(Object? body) {
    final data = _object(body);
    if (data['status'] != 'AWAITING_CONSENT' ||
        data['consentGranted'] != false ||
        data['confirmedAt'] != null ||
        data['consentRecordedAt'] != null) {
      throw const FormatException('Invalid restricted relationship');
    }
    _instant(data, 'codeUsedAt');
    return _relationship(data, CareLinkStatus.awaitingConsent);
  }

  /// Validates the exact acknowledged decision rather than inferring it from HTTP 200.
  static CareLink decided(Object? body, bool accepted) {
    final data = _object(body);
    if (data['status'] != (accepted ? 'CONFIRMED' : 'REVOKED') ||
        data['consentGranted'] != accepted) {
      throw const FormatException('Consent receipt mismatch');
    }
    _instant(data, 'consentRecordedAt');
    if (accepted) {
      _instant(data, 'confirmedAt');
    } else if (data['confirmedAt'] != null ||
        data['accessToken'] != null ||
        data['expiresAt'] != null) {
      throw const FormatException('Rejected consent cannot issue access');
    }
    return _relationship(
      data,
      accepted ? CareLinkStatus.confirmed : CareLinkStatus.revoked,
    );
  }

  /// Builds a credential only after the relationship and expected role are validated.
  static StoredSession issued(
    Object? body,
    CareLink link,
    SessionRole role,
    DateTime now,
  ) {
    final data = _object(body);
    final session = StoredSession(
      accessToken: _text(data, 'accessToken'),
      expiresAt: _instant(data, 'expiresAt'),
      owner: SessionOwner(link.olderAdultId, role, careLinkId: link.id),
    );
    if (!session.isValidAt(now)) {
      throw const FormatException('Expired issued session');
    }
    return session;
  }

  static CareLink _relationship(
    Map<String, dynamic> data,
    CareLinkStatus status,
  ) => CareLink(
    id: _text(data, 'id'),
    caregiverId: _text(data, 'caregiverId'),
    olderAdultId: _text(data, 'olderAdultId'),
    status: status,
  );

  static List<CaregiverLinkSummary> confirmed(Object? body) {
    if (body is! List) throw const FormatException();
    final ids = <String>{};
    final adults = <String>{};
    return List.unmodifiable(
      body.map((item) {
        final data = _object(item);
        final id = _text(data, 'id');
        final adult = _text(data, 'olderAdultId');
        if (!ids.add(id) || !adults.add(adult)) throw const FormatException();
        return CaregiverLinkSummary(
          id: id,
          olderAdultId: adult,
          fullName: _text(data, 'olderAdultName'),
          confirmedAt: _instant(data, 'confirmedAt'),
        );
      }),
    );
  }

  static OlderAdultProfile profile(Object? body) {
    final data = _object(body);
    final raw = _text(data, 'birthDate');
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(raw)) {
      throw const FormatException();
    }
    final date = DateTime.parse('${raw}T00:00:00Z');
    if (date.toIso8601String().substring(0, 10) != raw) {
      throw const FormatException();
    }
    return OlderAdultProfile(
      id: _text(data, 'id'),
      caregiverId: _text(data, 'registeredByCaregiverId'),
      fullName: _text(data, 'fullName'),
      birthDate: date,
    );
  }

  static CareLink pending(Object? body) {
    final data = _object(body);
    if (data['status'] != 'PENDING' ||
        data['consentGranted'] != false ||
        data['codeUsedAt'] != null ||
        data['accessToken'] != null ||
        data['expiresAt'] != null) {
      throw const FormatException();
    }
    return CareLink(
      id: _text(data, 'id'),
      caregiverId: _text(data, 'caregiverId'),
      olderAdultId: _text(data, 'olderAdultId'),
      status: CareLinkStatus.pending,
      code: LinkingCode(
        _text(data, 'linkingCode'),
        _instant(data, 'codeExpiresAt'),
      ),
    );
  }

  static Map<String, dynamic> _object(Object? body) {
    if (body is! Map<String, dynamic>) throw const FormatException();
    return body;
  }

  static String _text(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value is! String || value.isEmpty || value != value.trim()) {
      throw const FormatException();
    }
    return value;
  }

  static DateTime _instant(Map<String, dynamic> data, String key) {
    final value = _text(data, key);
    if (!RegExp(r'(Z|[+-]\d{2}:\d{2})$').hasMatch(value)) {
      throw const FormatException();
    }
    return DateTime.parse(value).toUtc();
  }
}
