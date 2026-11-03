import 'package:flutter_test/flutter_test.dart';
import 'package:tata/app/config/app_config.dart';

void main() {
  test('remote API requires HTTPS and a clean base path', () {
    for (final value in [
      'http://example.com/',
      'https://user:secret@example.com/',
      'https://example.com?token=x',
      'https://example.com/api',
    ]) {
      expect(
        () => AppConfig(apiBaseUrl: Uri.parse(value)),
        throwsArgumentError,
      );
    }
    expect(
      AppConfig(apiBaseUrl: Uri.parse('https://example.com/')).apiBaseUrl.host,
      'example.com',
    );
  });

  test('local HTTP is explicit and does not allow remote cleartext', () {
    expect(
      () => AppConfig(apiBaseUrl: Uri.parse('http://127.0.0.1:8080/')),
      throwsArgumentError,
    );
    expect(
      AppConfig(
        apiBaseUrl: Uri.parse('http://10.0.2.2:8080/'),
        allowLocalHttp: true,
      ).apiBaseUrl.port,
      8080,
    );
    expect(
      () => AppConfig(
        apiBaseUrl: Uri.parse('http://example.com/'),
        allowLocalHttp: true,
      ),
      throwsArgumentError,
    );
  });
}
