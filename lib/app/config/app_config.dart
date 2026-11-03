/// Runtime configuration, separate from credentials and platform files.
final class AppConfig {
  AppConfig({required Uri apiBaseUrl, bool allowLocalHttp = false})
    : apiBaseUrl = _validate(apiBaseUrl, allowLocalHttp);

  /// `TATA_ALLOW_LOCAL_HTTP` only admits cleartext to local development hosts,
  /// such as Spring on the host machine seen from the emulator at 10.0.2.2.
  factory AppConfig.fromEnvironment() => AppConfig(
    apiBaseUrl: Uri.parse(
      const String.fromEnvironment(
        'TATA_API_BASE_URL',
        defaultValue: 'https://web-services-yzxl.onrender.com/',
      ),
    ),
    allowLocalHttp: const bool.fromEnvironment('TATA_ALLOW_LOCAL_HTTP'),
  );

  final Uri apiBaseUrl;

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
}
