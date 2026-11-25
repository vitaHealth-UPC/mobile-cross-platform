/// Recognizes a typed adult access code such as `K7PM-Q2XD` (the hyphen and
/// letter case are optional). Anything else is treated as a full invitation.
abstract final class AccessCodeText {
  static final _pattern = RegExp(
    r'^[A-HJ-KM-NP-Z2-9]{4}-?[A-HJ-KM-NP-Z2-9]{4}$',
  );

  /// Normalized `XXXX-XXXX`, or null when [raw] is not an access code.
  static String? tryParse(String raw) {
    final compact = raw.trim().toUpperCase().replaceAll(' ', '');
    if (!_pattern.hasMatch(compact)) return null;
    final letters = compact.replaceAll('-', '');
    return '${letters.substring(0, 4)}-${letters.substring(4)}';
  }
}
