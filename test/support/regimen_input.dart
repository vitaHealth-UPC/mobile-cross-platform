import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Completes the regimen fields through their sheets, as a caregiver does:
/// a listed dose, a listed frequency and the default 08:00 start time (or one
/// manual 08:00 time for "Según indicación médica").
Future<void> fillRegimen(
  WidgetTester tester, {
  String prefix = 'treatment',
  String dose = '1 tableta',
  String frequency = 'Cada 12 horas',
}) async {
  Future<void> open(String key) async {
    final field = find.byKey(Key('$prefix-$key'));
    await tester.ensureVisible(field);
    await tester.pumpAndSettle();
    await tester.tap(field);
    await tester.pumpAndSettle();
  }

  await open('dose');
  await tester.tap(find.text(dose).last);
  await tester.pumpAndSettle();
  await open('frequency');
  await tester.tap(find.text(frequency).last);
  await tester.pumpAndSettle();
  final manual = find.byKey(const Key('add-schedule-time'));
  if (manual.evaluate().isNotEmpty) {
    await tester.ensureVisible(manual.first);
    await tester.pumpAndSettle();
    await tester.tap(manual.first);
  } else {
    await open('times');
  }
  await tester.pumpAndSettle();
  await tester.tap(
    find.text('ACEPTAR').evaluate().isNotEmpty
        ? find.text('ACEPTAR')
        : find.text('OK'),
  );
  await tester.pumpAndSettle();
}
