import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tata/features/treatment_management/application/readmodels/medication_registration_result.dart';
import 'package:tata/features/treatment_management/application/usecases/register_medication.dart';
import 'package:tata/features/treatment_management/application/usecases/update_medication.dart';
import 'package:tata/features/treatment_management/presentation/bloc/medication_registration/medication_registration_bloc.dart';
import 'package:tata/features/treatment_management/presentation/screens/medication_registration_screen.dart';
import 'package:tata/features/treatment_management/presentation/screens/treatment_setup_screen.dart';
import 'package:tata/l10n/generated/app_localizations.dart';
import 'package:tata/shared/common/result/app_result.dart';
import 'package:tata/shared/presentation/theme/tata_theme.dart';

import '../support/fake_treatment_backend.dart';
import '../support/visual_capture.dart';
import 'treatment_blocs_test.dart' show setupBloc;

/// Registration keeps regimen suggestions separate from medication persistence.
void main() {
  setUpAll(loadTataFonts);
  for (final scale in [1.0, 1.5]) {
    testWidgets('required medication notice renders at text scale $scale', (
      tester,
    ) async {
      final backend = FakeBackend();
      await _show(tester, backend, (_) {}, textScale: scale);
      if (scale > 1) tester.view.physicalSize = const Size(360, 640);
      await tester.runAsync(() async {
        await precacheImage(
          const AssetImage('assets/illustrations/registration_bottle.png'),
          tester.element(find.byType(MedicationRegistrationScreen)),
        );
      });
      await tester.pumpAndSettle();
      await _next(tester);
      await tester.ensureVisible(
        find.widgetWithText(ElevatedButton, 'Guardar medicamento'),
      );
      await tester.pumpAndSettle();
      expect(find.text('Faltan datos obligatorios'), findsOneWidget);
      expect(backend.medications.length, 1);
      await captureWidget(
        tester,
        find.byKey(const Key('registration-capture')),
        'medication-required-563-2404-$scale',
      );
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets(
    'only medication identity is required and no regimen is created',
    (tester) async {
      final backend = FakeBackend();
      MedicationRegistrationResult? result;
      await _show(tester, backend, (value) => result = value);
      await tester.enterText(
        find.byKey(const Key('medication-name')),
        'Losartán',
      );
      await tester.enterText(
        find.byKey(const Key('medication-presentation')),
        '50 mg, comprimido',
      );
      expect(find.byKey(const Key('medication-frequency')), findsNothing);
      await _next(tester);
      expect(result!.medication.name, 'Losartán');
      expect(result!.frequency, isEmpty);
      expect(result!.instructions, isEmpty);
      expect(backend.medications.length, 2);
      expect(backend.createCalls, 0);
      expect(backend.configureCalls, 0);
    },
  );
  testWidgets('regimen suggestions remain editable and never infer the dose', (
    tester,
  ) async {
    final backend = FakeBackend();
    await tester.pumpWidget(
      MaterialApp(
        theme: TataTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('es'),
        home: BlocProvider(
          create: (_) => setupBloc(backend),
          child: TreatmentSetupScreen(
            medicationLabel: 'Losartán 50 mg',
            initialFrequency: 'Cada 12 horas',
            initialInstructions: 'Con el desayuno\nPreparar agua',
            onFinished: () {},
            onSessionInvalidated: () {},
          ),
        ),
      ),
    );
    await tester.enterText(find.byKey(const Key('treatment-name')), 'Presión');
    Future<void> advance() async {
      final button = find.widgetWithText(ElevatedButton, 'Continuar');
      await tester.ensureVisible(button);
      await tester.pumpAndSettle();
      await tester.tap(button);
      await tester.pumpAndSettle();
    }

    await advance();
    expect(
      tester
          .widget<TextFormField>(find.byKey(const Key('treatment-dose')))
          .controller!
          .text,
      isEmpty,
    );
    expect(
      tester
          .widget<TextFormField>(find.byKey(const Key('treatment-frequency')))
          .controller!
          .text,
      'Cada 12 horas',
    );
    await tester.enterText(
      find.byKey(const Key('treatment-dose')),
      '1 comprimido',
    );
    expect(
      tester
          .widget<TextFormField>(
            find.byKey(const Key('treatment-instructions')),
          )
          .controller!
          .text,
      'Con el desayuno\nPreparar agua',
    );
    expect(
      tester
          .widget<TextFormField>(find.byKey(const Key('treatment-times')))
          .controller!
          .text,
      isEmpty,
    );
    expect(backend.configureCalls, 0);
  });
  testWidgets('registration renders native fields and the original bottle', (
    tester,
  ) async {
    await _show(tester, FakeBackend(), (_) {});
    await tester.runAsync(() async {
      final context = tester.element(find.byType(MedicationRegistrationScreen));
      await precacheImage(
        const AssetImage('assets/illustrations/registration_bottle.png'),
        context,
      );
    });
    await tester.pumpAndSettle();
    expect(find.text('Agregar medicamento: Rosa'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));
    await captureWidget(
      tester,
      find.byKey(const Key('registration-capture')),
      'medication-registration-563-453',
    );
    expect(tester.takeException(), isNull);
    await _show(tester, FakeBackend(), (_) {}, textScale: 1.5);
    tester.view.physicalSize = const Size(360, 640);
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.widgetWithText(ElevatedButton, 'Guardar medicamento'),
    );
    await tester.pumpAndSettle();
    await captureWidget(
      tester,
      find.byKey(const Key('registration-capture')),
      'medication-registration-563-453-150',
    );
    expect(tester.takeException(), isNull);
  });
  test(
    'registration and update reject fields beyond the backend limit',
    () async {
      final backend = FakeBackend();
      final tooLong = List.filled(161, 'x').join();
      final registered = await RegisterMedication(backend)(
        'adult-A',
        tooLong,
        '50 mg',
      );
      final updated = await UpdateMedication(backend)('med-1', 'Name', tooLong);
      expect(
        registered,
        isA<AppFailure>().having(
          (value) => value.code,
          'code',
          'MEDICATION_DETAILS_TOO_LONG',
        ),
      );
      expect(
        updated,
        isA<AppFailure>().having(
          (value) => value.code,
          'code',
          'MEDICATION_DETAILS_TOO_LONG',
        ),
      );
      expect(backend.medications.length, 1);
      expect(backend.medications['med-1']!.name, 'Metformina');
    },
  );

  testWidgets('blank identity cannot create a medication', (tester) async {
    final backend = FakeBackend();
    await _show(tester, backend, (_) {});
    await _next(tester);
    expect(find.text('Completa este campo.'), findsNWidgets(2));
    expect(find.byKey(const Key('medication-required-notice')), findsOneWidget);
    expect(backend.medications.length, 1);
  });

  testWidgets(
    'retry retains identity fields and returns the acknowledged medication',
    (tester) async {
      final backend = FakeBackend()..failure = 'NETWORK';
      MedicationRegistrationResult? result;
      await _show(tester, backend, (value) => result = value);
      for (final entry in {
        'medication-name': 'Losartán',
        'medication-presentation': '50 mg, comprimido',
      }.entries) {
        await tester.enterText(find.byKey(Key(entry.key)), entry.value);
      }
      await _next(tester);
      expect(result, isNull);
      expect(backend.medications.length, 1);
      expect(
        tester
            .widget<TextFormField>(
              find.byKey(const Key('medication-presentation')),
            )
            .controller!
            .text,
        '50 mg, comprimido',
      );
      backend.failure = null;
      await _next(tester);
      expect(result!.medication.id, 'med-2');
      expect(result!.frequency, isEmpty);
      expect(result!.instructions, isEmpty);
      expect(backend.createCalls, 0);
      expect(backend.configureCalls, 0);
    },
  );
}

Future<void> _show(
  WidgetTester tester,
  FakeBackend backend,
  ValueChanged<MedicationRegistrationResult> onRegistered, {
  double textScale = 1,
}) async {
  tester.view.physicalSize = const Size(393, 883);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: TataTheme.light,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('es'),
      home: RepaintBoundary(
        key: const Key('registration-capture'),
        child: BlocProvider(
          create: (_) => MedicationRegistrationBloc(
            register: RegisterMedication(backend),
            olderAdultId: 'adult-A',
          ),
          child: MedicationRegistrationScreen(
            personName: 'Rosa Vargas',
            onRegistered: onRegistered,
            onSessionInvalidated: () {},
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _next(WidgetTester tester) async {
  final button = find.widgetWithText(ElevatedButton, 'Guardar medicamento');
  await tester.ensureVisible(button);
  await tester.pumpAndSettle();
  await tester.tap(button);
  await tester.pumpAndSettle();
}
