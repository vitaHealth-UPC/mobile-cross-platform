import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tata/features/treatment_management/application/usecases/regimen_usecases.dart';
import 'package:tata/features/treatment_management/application/usecases/treatment_usecases.dart';
import 'package:tata/features/treatment_management/domain/value_objects/treatment_status.dart';
import 'package:tata/features/treatment_management/presentation/bloc/treatment_setup/treatment_setup_bloc.dart';
import 'package:tata/features/treatment_management/presentation/screens/treatment_setup_screen.dart';
import 'package:tata/l10n/generated/app_localizations.dart';
import 'package:tata/shared/presentation/theme/tata_theme.dart';

import '../support/fake_treatment_backend.dart';
import '../support/visual_capture.dart';
import 'treatment_blocs_test.dart' show FakeReader;

void main() {
  setUpAll(loadTataFonts);
  testWidgets('the wizard validates each step and activates the treatment', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(393, 883);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final backend = FakeBackend();
    var finished = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: TataTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('es'),
        home: BlocProvider(
          create: (_) => TreatmentSetupBloc(
            create: CreateTreatment(backend),
            basics: const SetDoseFrequency(),
            schedule: const SetScheduleInstructions(),
            reminder: const SetReminderPolicy(),
            read: GetTreatmentDetail(FakeReader(backend)),
            configure: ConfigureTreatment(backend),
            changeStatus: ChangeTreatmentStatus(backend),
            olderAdultId: 'adult-A',
            medicationId: 'med-1',
          ),
          child: TreatmentSetupScreen(
            medicationLabel: 'Metformina · 500 mg',
            onFinished: () => finished = true,
            onSessionInvalidated: () {},
          ),
        ),
      ),
    );

    // Step 1: an empty name is refused locally and nothing is created.
    await tester.ensureVisible(
      find.widgetWithText(ElevatedButton, 'Continuar'),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Continuar'));
    await tester.pumpAndSettle();
    expect(find.text('Completa este campo.'), findsOneWidget);
    expect(backend.createCalls, 0);
    await tester.enterText(find.byKey(const Key('treatment-name')), 'Diabetes');
    await tester.ensureVisible(
      find.widgetWithText(ElevatedButton, 'Continuar'),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Continuar'));
    await tester.pumpAndSettle();
    expect(backend.createCalls, 1);

    // Step 2.
    await tester.enterText(
      find.byKey(const Key('treatment-dose')),
      '1 tableta',
    );
    await tester.enterText(
      find.byKey(const Key('treatment-frequency')),
      'cada 12 horas',
    );
    await tester.ensureVisible(
      find.widgetWithText(ElevatedButton, 'Continuar'),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Continuar'));
    await tester.pumpAndSettle();

    // Step 3: a malformed time shows the stable error message.
    await tester.enterText(find.byKey(const Key('treatment-times')), '8am');
    await tester.ensureVisible(
      find.widgetWithText(ElevatedButton, 'Continuar'),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Continuar'));
    await tester.pumpAndSettle();
    expect(
      find.text('Usa horarios en formato HH:mm, por ejemplo 08:00.'),
      findsOneWidget,
    );
    await tester.enterText(
      find.byKey(const Key('treatment-times')),
      '20:00, 8:00',
    );
    await tester.ensureVisible(
      find.widgetWithText(ElevatedButton, 'Continuar'),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Continuar'));
    await tester.pumpAndSettle();

    // Step 4: blank keeps the system default; step 5 shows the normalized review.
    await tester.ensureVisible(
      find.widgetWithText(ElevatedButton, 'Continuar'),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Continuar'));
    await tester.pumpAndSettle();
    expect(find.text('Diabetes'), findsOneWidget);
    expect(find.textContaining('08:00, 20:00'), findsOneWidget);
    expect(find.textContaining('Predeterminado del sistema'), findsOneWidget);

    await tester.ensureVisible(
      find.widgetWithText(ElevatedButton, 'Activar tratamiento'),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.widgetWithText(ElevatedButton, 'Activar tratamiento'),
    );
    await tester.pumpAndSettle();
    expect(backend.stored!.status, TreatmentStatus.active);
    expect(finished, isTrue);
    expect(tester.takeException(), isNull);
  });
}
