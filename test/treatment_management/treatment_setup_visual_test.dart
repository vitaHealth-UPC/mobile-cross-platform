import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tata/features/treatment_management/presentation/bloc/treatment_setup/treatment_setup_bloc.dart';
import 'package:tata/features/treatment_management/presentation/bloc/treatment_setup/treatment_setup_event.dart';
import 'package:tata/features/treatment_management/presentation/bloc/treatment_setup/treatment_setup_state.dart';
import 'package:tata/features/treatment_management/presentation/screens/treatment_setup_screen.dart';
import 'package:tata/l10n/generated/app_localizations.dart';
import 'package:tata/shared/presentation/theme/tata_theme.dart';

import '../support/fake_treatment_backend.dart';
import '../support/visual_capture.dart';
import 'treatment_blocs_test.dart' show setupBloc;

void main() {
  setUpAll(loadTataFonts);
  Future<void> pump(
    WidgetTester tester,
    TreatmentSetupBloc bloc,
    double scale,
  ) async {
    tester.view.physicalSize = scale == 1
        ? const Size(393, 883)
        : const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: TataTheme.light,
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: RepaintBoundary(
            key: const Key('setup-capture'),
            child: child!,
          ),
        ),
        home: BlocProvider.value(
          value: bloc,
          child: TreatmentSetupScreen(
            medicationLabel: 'Losartán 50 mg',
            onFinished: () {},
            onSessionInvalidated: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final step in TreatmentSetupStep.values) {
    for (final scale in [1.0, 1.5]) {
      testWidgets('setup ${step.name} renders with text scale $scale', (
        tester,
      ) async {
        final bloc = setupBloc(FakeBackend());
        addTearDown(bloc.close);
        if (step.index > 0) {
          bloc.add(const TreatmentDraftSubmitted('Control de presión'));
          await tester.pump();
        }
        if (step.index > 1) {
          bloc.add(const RegimenBasicsSubmitted('1 comprimido', 'Cada día'));
          await tester.pump();
        }
        if (step.index > 2) {
          bloc.add(const ScheduleSubmitted('08:00', 'Con agua'));
          await tester.pump();
        }
        if (step.index > 3) {
          bloc.add(const ReminderSubmitted('10'));
          await tester.pump();
        }
        await pump(tester, bloc, scale);
        if (step == TreatmentSetupStep.details) {
          await tester.enterText(
            find.byKey(const Key('treatment-name')),
            'Control de presión',
          );
        }
        if (step == TreatmentSetupStep.regimen) {
          await tester.enterText(
            find.byKey(const Key('treatment-dose')),
            '1 comprimido',
          );
          await tester.enterText(
            find.byKey(const Key('treatment-frequency')),
            'Cada día',
          );
        }
        if (step == TreatmentSetupStep.schedule) {
          await tester.enterText(
            find.byKey(const Key('treatment-times')),
            '08:00',
          );
          await tester.enterText(
            find.byKey(const Key('treatment-instructions')),
            'Con agua',
          );
        }
        if (step == TreatmentSetupStep.reminders) {
          await tester.enterText(
            find.byKey(const Key('treatment-delay')),
            '10',
          );
        }
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await captureWidget(
          tester,
          find.byKey(const Key('setup-capture')),
          'treatment_setup_${step.name}_${scale == 1 ? 'normal' : 'large'}',
        );
        final button = find.byType(ElevatedButton);
        await tester.ensureVisible(button);
        await tester.pumpAndSettle();
        expect(button.hitTestable(), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }
  testWidgets('returning to saved draft shows an immutable acknowledged name', (
    tester,
  ) async {
    final backend = FakeBackend();
    final bloc = setupBloc(backend);
    addTearDown(bloc.close);
    await pump(tester, bloc, 1);
    await tester.enterText(
      find.byKey(const Key('treatment-name')),
      'Control de presión',
    );
    await tester.tap(find.widgetWithText(ElevatedButton, 'Continuar'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Volver'));
    await tester.pumpAndSettle();
    final field = tester.widget<TextFormField>(
      find.byKey(const Key('treatment-name')),
    );
    expect(
      tester
          .widget<TextField>(
            find.descendant(
              of: find.byKey(const Key('treatment-name')),
              matching: find.byType(TextField),
            ),
          )
          .readOnly,
      isTrue,
    );
    expect(field.controller!.text, 'Control de presión');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Continuar'));
    await tester.pumpAndSettle();
    expect(backend.createCalls, 1);
  });
}
