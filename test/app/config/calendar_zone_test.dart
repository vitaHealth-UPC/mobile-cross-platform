import 'package:flutter_test/flutter_test.dart';
import 'package:tata/app/config/app_config.dart';

void main() {
  final base = Uri.parse('https://example.com/');

  test('the calendar zone defaults to the backend zone', () {
    expect(AppConfig(apiBaseUrl: base).calendarZone, 'America/Lima');
    expect(defaultCalendarZone, 'America/Lima');
  });

  test('accepts IANA region identifiers', () {
    for (final zone in [
      'America/Lima',
      'America/Argentina/Buenos_Aires',
      'Etc/GMT+5',
    ]) {
      expect(
        AppConfig(apiBaseUrl: base, calendarZone: zone).calendarZone,
        zone,
      );
    }
  });

  test('rejects values that are not a zone identifier', () {
    for (final zone in [
      '',
      'Lima',
      'America/Lima&days=1',
      'America/Lima extra',
      '../etc/passwd',
      'America/',
    ]) {
      expect(
        () => AppConfig(apiBaseUrl: base, calendarZone: zone),
        throwsArgumentError,
        reason: zone,
      );
    }
  });
}
