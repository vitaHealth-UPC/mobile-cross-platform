/// IANA calendar zone the backend uses when a client does not say otherwise.
const defaultCalendarZone = 'America/Lima';

/// Runtime configuration, separate from credentials and platform files.
final class AppConfig {
  AppConfig({
    required Uri apiBaseUrl,
    bool allowLocalHttp = false,
    String calendarZone = defaultCalendarZone,
  }) : apiBaseUrl = _validate(apiBaseUrl, allowLocalHttp),
       calendarZone = _validateZone(calendarZone);

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
  );

  final Uri apiBaseUrl;

  /// IANA zone identifier such as `America/Lima`, sent with adherence reads.
  final String calendarZone;

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
