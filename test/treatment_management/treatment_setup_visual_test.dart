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
import '../support/regimen_input.dart';
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
          bloc.add(
            const RegimenBasicsSubmitted('1 comprimido', 'Una vez al día'),
          );
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
          await fillRegimen(tester, frequency: 'Una vez al día');
          await tester.drag(
            find.byType(SingleChildScrollView).first,
            const Offset(0, 2000),
          );
        }
        if (step == TreatmentSetupStep.schedule) {
          final times = find.byKey(const Key('treatment-times'));
          await tester.ensureVisible(times);
          await tester.pumpAndSettle();
          await tester.tap(times);
          await tester.pumpAndSettle();
          await tester.tap(find.text('ACEPTAR'));
          await tester.pumpAndSettle();
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
  for (final scale in [1.0, 1.5]) {
    testWidgets(
      'server-rejected configuration returns to the saved regimen at scale $scale',
      (tester) async {
        final backend = FakeBackend();
        final bloc = setupBloc(backend);
        addTearDown(bloc.close);
        bloc.add(const TreatmentDraftSubmitted('Control de presión'));
        await tester.pump();
        bloc.add(
          const RegimenBasicsSubmitted('1 comprimido', 'Una vez al día'),
        );
        await tester.pump();
        bloc.add(const ScheduleSubmitted('08:00', 'Con agua'));
        await tester.pump();
        bloc.add(const ReminderSubmitted('10'));
        await tester.pump();
        backend.configureFailure = 'INVALID_TREATMENT_CONFIGURATION';
        await pump(tester, bloc, scale);
        final activate = find.widgetWithText(
          ElevatedButton,
          'Activar tratamiento',
        );
        await tester.ensureVisible(activate);
        await tester.pumpAndSettle();
        await tester.tap(activate);
        await tester.pumpAndSettle();
        expect(find.text('Configuración incompleta'), findsOneWidget);
        await tester.drag(
          find.byType(SingleChildScrollView).first,
          const Offset(0, 1000),
        );
        await tester.pumpAndSettle();
        await captureWidget(
          tester,
          find.byKey(const Key('setup-capture')),
          'treatment_incomplete_${scale == 1 ? 'normal' : 'large'}',
        );
        final complete = find.widgetWithText(
          ElevatedButton,
          'Completar configuración',
        );
        await tester.ensureVisible(complete);
        await tester.pumpAndSettle();
        await tester.tap(complete);
        await tester.pumpAndSettle();
        expect(bloc.state.step, TreatmentSetupStep.regimen);
        expect(
          find.descendant(
            of: find.byKey(const Key('treatment-dose')),
            matching: find.text('1 comprimido'),
          ),
          findsOneWidget,
        );
        expect(backend.createCalls, 1);
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets('returning to the details keeps the typed name editable', (
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
    final next = find.widgetWithText(ElevatedButton, 'Continuar');
    await tester.ensureVisible(next);
    await tester.pumpAndSettle();
    await tester.tap(next);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Volver'));
    await tester.pumpAndSettle();
    final field = tester.widget<TextFormField>(
      find.byKey(const Key('treatment-name')),
    );
    // No draft exists before activation, so the name can still change.
    expect(field.controller!.text, 'Control de presión');
    expect(
      tester
          .widget<TextField>(
            find.descendant(
              of: find.byKey(const Key('treatment-name')),
              matching: find.byType(TextField),
            ),
          )
          .readOnly,
      isFalse,
    );
    expect(backend.createCalls, 0);
  });
}
