/// IANA calendar zone the backend uses when a client does not say otherwise.
const defaultCalendarZone = 'America/Lima';

/// Runtime configuration, separate from credentials and platform files.
final class AppConfig {
  AppConfig({
    required Uri apiBaseUrl,
    bool allowLocalHttp = false,
    String calendarZone = defaultCalendarZone,
    String contactUrl = '',
  }) : apiBaseUrl = _validate(apiBaseUrl, allowLocalHttp),
       calendarZone = _validateZone(calendarZone),
       contactUri = contactDestination(contactUrl);

  /// `TATA_ALLOW_LOCAL_HTTP` only admits cleartext to local development hosts,
  /// such as Spring on the host machine seen from the emulator at 10.0.2.2.
  /// `TATA_CALENDAR_ZONE` selects the zone that buckets days and time bands in
  /// adherence views.
  factory AppConfig.fromEnvironment() => AppConfig(
    apiBaseUrl: Uri.parse(
      const String.fromEnvironment(
        'TATA_API_BASE_URL',
        defaultValue: 'https://web-services-yzxl.onrender.com/',
      ),
    ),
    allowLocalHttp: const bool.fromEnvironment('TATA_ALLOW_LOCAL_HTTP'),
    calendarZone: const String.fromEnvironment(
      'TATA_CALENDAR_ZONE',
      defaultValue: defaultCalendarZone,
    ),
    contactUrl: const String.fromEnvironment('TATA_CONTACT_URL'),
  );

  final Uri apiBaseUrl;

  /// IANA zone identifier such as `America/Lima`, sent with adherence reads.
  final String calendarZone;

  /// `TATA_CONTACT_URL`: where a visitor reaches the team (US-49). Null when it
  /// is missing or invalid, so the app shows the contact as unavailable.
  final Uri? contactUri;

  /// Accepts only `https`, `mailto` and `tel` destinations with a target.
  static Uri? contactDestination(String value) {
    final uri = Uri.tryParse(value.trim());
    if (uri == null || uri.userInfo.isNotEmpty) return null;
    return switch (uri.scheme) {
      'https' when uri.host.isNotEmpty => uri,
      'mailto' || 'tel' when uri.path.trim().isNotEmpty => uri,
      _ => null,
    };
  }

  static Uri _validate(Uri value, bool allowLocalHttp) {
    final local = const {'localhost', '127.0.0.1', '10.0.2.2', '::1'};
    if (value.host.isEmpty ||
        value.userInfo.isNotEmpty ||
        value.hasQuery ||
        value.hasFragment ||
        !value.path.endsWith('/') ||
        (value.scheme != 'https' &&
            !(allowLocalHttp &&
                value.scheme == 'http' &&
                local.contains(value.host)))) {
      throw ArgumentError('Invalid API base URL');
    }
    return value;
  }

  // Region/City identifiers only: the value is sent as a query parameter.
  static String _validateZone(String value) {
    if (!RegExp(r'^[A-Za-z_]+(/[A-Za-z0-9_+-]+)+$').hasMatch(value)) {
      throw ArgumentError('Invalid calendar zone');
    }
    return value;
  }
}
