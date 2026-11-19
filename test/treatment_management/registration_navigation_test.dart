import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tata/features/treatment_management/application/usecases/medication_usecases.dart';
import 'package:tata/features/treatment_management/application/usecases/regimen_usecases.dart';
import 'package:tata/features/treatment_management/application/usecases/treatment_usecases.dart';
import 'package:tata/features/treatment_management/domain/value_objects/treatment_status.dart';
import 'package:tata/features/treatment_management/presentation/bloc/medication_management/medication_management_bloc.dart';
import 'package:tata/features/treatment_management/presentation/bloc/medication_registration/medication_registration_bloc.dart';
import 'package:tata/features/treatment_management/presentation/bloc/treatment_setup/treatment_setup_bloc.dart';
import 'package:tata/features/treatment_management/presentation/navigation/treatment_navigation.dart';
import 'package:tata/features/treatment_management/presentation/screens/medication_management_screen.dart';
import 'package:tata/features/treatment_management/presentation/screens/treatment_setup_screen.dart';
import 'package:tata/l10n/generated/app_localizations.dart';
import 'package:tata/shared/presentation/theme/tata_theme.dart';

import '../support/fake_treatment_backend.dart';
import 'treatment_blocs_test.dart' show FakeReader;

/// Exercises actual route ownership and receipts across registration and setup.
void main() {
  testWidgets(
    'catalog registration carries the acknowledged medication into activation',
    (tester) async {
      final backend = FakeBackend();
      await _openCatalog(tester, backend);
      await _register(tester);
      expect(find.byType(TreatmentSetupScreen), findsOneWidget);
      expect(backend.medications.length, 2);
      expect(backend.createCalls, 0);
      await tester.enterText(
        find.byKey(const Key('treatment-name')),
        'Presión',
      );
      await _button(tester, 'Continuar');
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
      await _button(tester, 'Continuar');
      expect(
        tester
            .widget<TextFormField>(
              find.byKey(const Key('treatment-instructions')),
            )
            .controller!
            .text,
        'Con el desayuno\nPreparar agua',
      );
      await tester.enterText(
        find.byKey(const Key('treatment-times')),
        '08:00, 20:00',
      );
      await _button(tester, 'Continuar');
      await _button(tester, 'Continuar');
      expect(backend.configureCalls, 0);
      await _button(tester, 'Activar tratamiento');
      expect(backend.stored!.status, TreatmentStatus.active);
      expect(backend.stored!.medicationId, 'med-2');
      expect(backend.stored!.dose, '1 comprimido');
      expect(backend.stored!.frequency, 'Cada 12 horas');
      expect(backend.stored!.scheduledTimes, ['08:00', '20:00']);
      expect(backend.stored!.instructions, 'Con el desayuno\nPreparar agua');
      expect(backend.configureCalls, 1);
      expect(find.byType(MedicationManagementScreen), findsOneWidget);
      expect(find.byType(TreatmentSetupScreen), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'leaving setup keeps the registered medication without another registration',
    (tester) async {
      final backend = FakeBackend();
      await _openCatalog(tester, backend);
      await _register(tester);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(MedicationManagementScreen), findsOneWidget);
      expect(backend.medications.length, 2);
      expect(backend.createCalls, 0);
      expect(backend.configureCalls, 0);
      expect(find.textContaining('Losartán'), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );
}

Future<void> _openCatalog(WidgetTester tester, FakeBackend backend) async {
  tester.view.physicalSize = const Size(393, 883);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final navigation = TreatmentNavigation(
    TreatmentFactories(
      createListBloc: (_) => throw UnimplementedError(),
      createRegistrationBloc: (adult) => MedicationRegistrationBloc(
        register: RegisterMedication(backend),
        olderAdultId: adult,
      ),
      createMedicationsBloc: (adult) => MedicationManagementBloc(
        list: ListMedications(backend),
        update: UpdateMedication(backend),
        deactivate: DeactivateMedication(backend),
        reactivate: ReactivateMedication(backend),
        olderAdultId: adult,
      ),
      createSetupBloc: (adult, medication) => TreatmentSetupBloc(
        create: CreateTreatment(backend),
        basics: const SetDoseFrequency(),
        schedule: const SetScheduleInstructions(),
        reminder: const SetReminderPolicy(),
        read: GetTreatmentDetail(FakeReader(backend)),
        configure: ConfigureTreatment(backend),
        changeStatus: ChangeTreatmentStatus(backend),
        olderAdultId: adult,
        medicationId: medication,
      ),
      createManagementBloc: (_, _) => throw UnimplementedError(),
      createMyMedicationsBloc: () => throw UnimplementedError(),
    ),
  );
  await tester.pumpWidget(
    MaterialApp(
      theme: TataTheme.light,
      locale: const Locale('es'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => navigation.openMedications(
              context,
              'adult-A',
              () {},
              personName: 'Rosa Vargas',
            ),
            child: const Text('Abrir catálogo'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Abrir catálogo'));
  await tester.pumpAndSettle();
}

Future<void> _register(WidgetTester tester) async {
  await tester.tap(find.text('Registrar medicamento'));
  await tester.pumpAndSettle();
  for (final entry in {
    'medication-name': 'Losartán',
    'medication-presentation': '50 mg, comprimido',
    'medication-frequency': 'Cada 12 horas',
    'medication-when': 'Con el desayuno',
    'medication-notes': 'Preparar agua',
  }.entries) {
    await tester.enterText(find.byKey(Key(entry.key)), entry.value);
  }
  await _button(tester, 'Siguiente');
}

Future<void> _button(WidgetTester tester, String text) async {
  final button = find.widgetWithText(ElevatedButton, text);
  await tester.ensureVisible(button);
  await tester.pumpAndSettle();
  await tester.tap(button);
  await tester.pumpAndSettle();
}
