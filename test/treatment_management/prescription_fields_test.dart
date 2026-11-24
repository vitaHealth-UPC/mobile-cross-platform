import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tata/features/treatment_management/presentation/widgets/prescription_fields.dart';
import 'package:tata/l10n/generated/app_localizations.dart';

void main() {
  testWidgets(
    'selects supported frequencies and adds distinct times by clock',
    (tester) async {
      final frequency = TextEditingController();
      final times = TextEditingController();
      addTearDown(frequency.dispose);
      addTearDown(times.dispose);
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: ListView(
              children: [
                FrequencyField(
                  controller: frequency,
                  fieldKey: const Key('frequency'),
                ),
                ScheduleTimeField(
                  controller: times,
                  frequency: frequency,
                  fieldKey: const Key('times'),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.tap(find.byTooltip('Select frequency'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Every 8 hours').last);
      await tester.pumpAndSettle();
      expect(frequency.text, 'Every 8 hours');
      expect(
        tester.widget<TextField>(find.byType(TextField).first).readOnly,
        isTrue,
      );
      final add = find.widgetWithText(OutlinedButton, 'Add time');
      for (var i = 0; i < 2; i++) {
        await tester.tap(add);
        await tester.pumpAndSettle();
        expect(find.byType(TimePickerDialog), findsOneWidget);
        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();
        expect(times.text, '08:00');
      }
      await tester.tap(add);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel', findRichText: true));
      await tester.pumpAndSettle();
      expect(times.text, '08:00');
      expect(find.byType(InputChip), findsOneWidget);
      await tester.tap(find.byTooltip('Remove time 08:00'));
      await tester.pumpAndSettle();
      expect(times.text, isEmpty);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
