import 'dart:convert';

/// Versioned, copyable invitation carrying both fields required by acceptance.
/// It is a transport envelope, not a session or proof that consent was granted.
final class CareLinkInvitation {
  CareLinkInvitation({required this.caregiverId, required String code})
    : code = code.trim().toUpperCase() {
    if (caregiverId.isEmpty ||
        caregiverId != caregiverId.trim() ||
        RegExp(r'\s').hasMatch(caregiverId) ||
        this.code.isEmpty ||
        this.code.length > 32) {
      throw const FormatException('Invalid care invitation');
    }
  }
  final String caregiverId;
  final String code;
  static const _prefix = 'tata-link:v1:';

  /// Parses bounded text pasted by the user without accepting arbitrary URLs.
  factory CareLinkInvitation.fromText(String value) {
    final text = value.trim();
    if (text.length > 2048 || !text.startsWith(_prefix)) {
      throw const FormatException('Invalid care invitation');
    }
    final encoded = base64Url.normalize(text.substring(_prefix.length));
    final body = jsonDecode(utf8.decode(base64Url.decode(encoded)));
    if (body is! Map<String, dynamic> ||
        body['caregiverId'] is! String ||
        body['code'] is! String) {
      throw const FormatException('Invalid care invitation');
    }
    return CareLinkInvitation(
      caregiverId: body['caregiverId'] as String,
      code: body['code'] as String,
    );
  }

  /// Produces a self-contained invitation without exporting a caregiver bearer.
  String encode() =>
      _prefix +
      base64Url.encode(
        utf8.encode(jsonEncode({'caregiverId': caregiverId, 'code': code})),
      );

  @override
  String toString() => 'CareLinkInvitation[REDACTED]';
}
