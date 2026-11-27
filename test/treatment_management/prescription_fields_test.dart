import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tata/features/treatment_management/presentation/widgets/prescription_fields.dart';
import 'package:tata/l10n/generated/app_localizations.dart';

Future<void> _pump(WidgetTester tester, Widget child, {String locale = 'en'}) =>
    tester.pumpWidget(
      MaterialApp(
        locale: Locale(locale),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ListView(children: [Form(child: child)]),
        ),
      ),
    );

void main() {
  testWidgets('an interval derives every time of the day from the start', (
    tester,
  ) async {
    final dose = TextEditingController();
    final frequency = TextEditingController();
    final times = TextEditingController();
    final instructions = TextEditingController();
    for (final c in [dose, frequency, times, instructions]) {
      addTearDown(c.dispose);
    }
    await _pump(
      tester,
      RegimenFields(
        dose: dose,
        frequency: frequency,
        times: times,
        instructions: instructions,
      ),
    );
    // The frequency field never opens the keyboard: it shows one sheet.
    expect(find.byType(EditableText), findsOneWidget);
    await tester.tap(find.byKey(const Key('treatment-frequency')));
    await tester.pumpAndSettle();
    expect(find.text('Select frequency'), findsWidgets);
    await tester.tap(find.text('Every 6 hours').last);
    await tester.pumpAndSettle();
    expect(frequency.text, 'Every 6 hours');

    await tester.tap(find.byKey(const Key('treatment-times')));
    await tester.pumpAndSettle();
    expect(find.byType(TimePickerDialog), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(times.text, '02:00,08:00,14:00,20:00');
    expect(find.text('4 doses a day'), findsOneWidget);
    expect(find.text('14:00'), findsOneWidget);

    // A new interval keeps the start and derives the new cycle.
    await tester.tap(find.byKey(const Key('treatment-frequency')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('frequency-other-interval')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('interval-4')));
    await tester.pumpAndSettle();
    expect(frequency.text, 'Every 4 hours');
    expect(times.text, '00:00,04:00,08:00,12:00,16:00,20:00');

    // "As prescribed" switches to manual times.
    await tester.tap(find.byKey(const Key('treatment-frequency')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('As prescribed').last);
    await tester.pumpAndSettle();
    expect(times.text, isEmpty);
    await tester.ensureVisible(find.byKey(const Key('add-schedule-time')));
    await tester.tap(find.byKey(const Key('add-schedule-time')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(times.text, '08:00');
    await tester.tap(find.byTooltip('Remove time 08:00'));
    await tester.pumpAndSettle();
    expect(times.text, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('explicitly edits generated times as a prescribed schedule', (
    tester,
  ) async {
    final dose = TextEditingController();
    final frequency = TextEditingController(text: 'Every 6 hours');
    final times = TextEditingController(text: '02:00,08:00,14:00,20:00');
    final instructions = TextEditingController();
    for (final controller in [dose, frequency, times, instructions]) {
      addTearDown(controller.dispose);
    }
    await _pump(
      tester,
      RegimenFields(
        dose: dose,
        frequency: frequency,
        times: times,
        instructions: instructions,
      ),
    );
    final edit = find.text('Edit times as prescribed');
    await tester.ensureVisible(edit);
    await tester.tap(edit);
    await tester.pumpAndSettle();
    expect(frequency.text, 'As prescribed');
    expect(times.text, '02:00,08:00,14:00,20:00');
    final remove = find.byTooltip('Remove time 02:00');
    await tester.ensureVisible(remove);
    await tester.tap(remove);
    await tester.pumpAndSettle();
    expect(times.text, '08:00,14:00,20:00');
  });

  testWidgets('dose and meals are chosen in sheets without typing', (
    tester,
  ) async {
    final dose = TextEditingController();
    final frequency = TextEditingController();
    final times = TextEditingController();
    final instructions = TextEditingController(text: 'Shake well');
    for (final c in [dose, frequency, times, instructions]) {
      addTearDown(c.dispose);
    }
    await _pump(
      tester,
      RegimenFields(
        dose: dose,
        frequency: frequency,
        times: times,
        instructions: instructions,
      ),
    );
    await tester.tap(find.byKey(const Key('treatment-dose')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('dose-custom')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('dose-increase')));
    await tester.tap(find.byKey(const Key('dose-increase')));
    await tester.tap(find.byKey(const Key('dose-increase')));
    await tester.pump();
    expect(find.text('2 ½'), findsOneWidget);
    await tester.tap(find.byKey(const Key('dose-apply')));
    await tester.pumpAndSettle();
    expect(dose.text, '2 ½ tablets');

    await tester.ensureVisible(find.byKey(const Key('treatment-meals')));
    await tester.tap(find.byKey(const Key('treatment-meals')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('After'));
    await tester.tap(find.byKey(const Key('meal-2')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('meals-apply')));
    await tester.pumpAndSettle();
    // Meal timing leads the instructions; free text is preserved after it.
    expect(instructions.text, 'After breakfast and dinner\nShake well');
  });

  testWidgets('Spanish meal sentence uses the "del" contraction', (
    tester,
  ) async {
    final meal = TextEditingController();
    addTearDown(meal.dispose);
    await _pump(
      tester,
      MealTimingField(controller: meal, fieldKey: const Key('meals')),
      locale: 'es',
    );
    await tester.tap(find.byKey(const Key('meals')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('meal-2')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('meals-apply')));
    await tester.pumpAndSettle();
    expect(meal.text, 'Después del desayuno y la cena');
  });
}
