import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tata/features/treatment_management/application/usecases/change_treatment_status.dart';
import 'package:tata/features/treatment_management/application/usecases/configure_treatment.dart';
import 'package:tata/features/treatment_management/application/usecases/create_treatment.dart';
import 'package:tata/features/treatment_management/application/usecases/deactivate_medication.dart';
import 'package:tata/features/treatment_management/application/usecases/delete_medication.dart';
import 'package:tata/features/treatment_management/application/usecases/get_treatment_detail.dart';
import 'package:tata/features/treatment_management/application/usecases/list_medications.dart';
import 'package:tata/features/treatment_management/application/usecases/reactivate_medication.dart';
import 'package:tata/features/treatment_management/application/usecases/register_medication.dart';
import 'package:tata/features/treatment_management/application/usecases/set_dose_frequency.dart';
import 'package:tata/features/treatment_management/application/usecases/set_reminder_policy.dart';
import 'package:tata/features/treatment_management/application/usecases/set_schedule_instructions.dart';
import 'package:tata/features/treatment_management/application/usecases/update_medication.dart';
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
import '../support/regimen_input.dart';
import 'treatment_blocs_test.dart' show FakeReader;

/// Exercises actual route ownership and receipts across registration and setup.
void main() {
  testWidgets(
    'delete is available for active and retired medications and waits for acknowledgement',
    (tester) async {
      final backend = FakeBackend();
      await _openCatalog(tester, backend);
      Future<void> delete(String id) => _action(tester, id, 'Eliminar');
      final confirm = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Eliminar'),
      );
      await delete('med-1');
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(backend.medications.length, 1);
      await delete('med-1');
      backend.failure = 'REQUEST_FAILED';
      await tester.tap(confirm);
      await tester.pumpAndSettle();
      expect(backend.medications.length, 1);
      expect(find.text('Medicamento eliminado.'), findsNothing);
      backend.failure = null;
      await _action(tester, 'med-1', 'Retirar');
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Retirar'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Medicamentos retirados'), findsOneWidget);
      await delete('med-1');
      await tester.tap(confirm);
      await tester.pumpAndSettle();
      expect(backend.medications, isEmpty);
      expect(find.text('Medicamento eliminado.'), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);
      await _register(tester);
      await delete(backend.medications.keys.single);
      await tester.tap(confirm);
      await tester.pumpAndSettle();
      expect(backend.medications, isEmpty);
      expect(find.text('Medicamento eliminado.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('catalog and retirement receipt fit 150 percent text', (
    tester,
  ) async {
    final backend = FakeBackend();
    await _openCatalog(tester, backend, scale: 1.5);
    await _action(tester, 'med-1', 'Retirar');
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Retirar'),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('medication-operation-receipt')),
      findsOneWidget,
    );
    expect(find.byType(SnackBar), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('empty catalog can register, retire and restore medication', (
    tester,
  ) async {
    final backend = FakeBackend();
    backend.medications.clear();
    await _openCatalog(tester, backend);
    expect(find.text('Tu lista de medicamentos está vacía'), findsOneWidget);
    expect(find.text('Registrar medicamento'), findsOneWidget);
    expect(
      tester.widget<Text>(find.text('Medicamentos')).style!.fontFamily,
      'DMSerifDisplay',
    );
    await _register(tester);
    expect(backend.medications.length, 1);
    expect(find.text('Medicamento registrado.'), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);
    final registered = backend.medications.keys.single;
    await _action(tester, registered, 'Retirar');
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Retirar'),
      ),
    );
    await tester.pumpAndSettle();
    expect(backend.medications.values.single.active, isFalse);
    expect(find.text('Medicamentos retirados'), findsOneWidget);
    expect(find.text('Medicamento desactivado.'), findsOneWidget);
    expect(
      find.byKey(const Key('medication-operation-receipt')),
      findsOneWidget,
    );
    expect(find.byType(SnackBar), findsNothing);
    await _action(tester, registered, 'Reactivar');
    expect(backend.medications.values.single.active, isTrue);
    expect(find.text('Medicamento reactivado.'), findsOneWidget);
    expect(find.text('Medicamento desactivado.'), findsNothing);
    expect(find.byType(SnackBar), findsNothing);
    expect(backend.medications.length, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'catalog saves identity and explicitly opens a single treatment setup',
    (tester) async {
      final backend = FakeBackend();
      await _openCatalog(tester, backend);
      await _register(tester);
      expect(find.byType(TreatmentSetupScreen), findsNothing);
      expect(find.textContaining('Losartán'), findsWidgets);
      await _button(tester, 'Crear tratamiento');
      expect(find.byType(TreatmentSetupScreen), findsOneWidget);
      expect(backend.medications.length, 2);
      expect(backend.createCalls, 0);
      // The wizard starts without medications; the caregiver picks them.
      await tester.enterText(
        find.byKey(const Key('treatment-name')),
        'Presión',
      );
      await _button(tester, 'Continuar');
      expect(
        find.text('Agrega al menos un medicamento al tratamiento.'),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('treatment-add-medication')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('choose-med-2')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('medications-done')));
      await tester.pumpAndSettle();
      expect(find.text('Losartán 50 mg, comprimido'), findsOneWidget);
      await _button(tester, 'Continuar');
      await fillRegimen(tester);
      await tester.enterText(
        find.byKey(const Key('treatment-instructions')),
        'Con el desayuno\nPreparar agua',
      );
      await _button(tester, 'Continuar');
      await _button(tester, 'Continuar');
      expect(backend.configureCalls, 0);
      await _button(tester, 'Activar tratamiento');
      expect(backend.stored!.status, TreatmentStatus.active);
      expect(find.text('Tratamiento activado.'), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);
      expect(backend.stored!.medicationId, 'med-2');
      expect(backend.stored!.dose, '1 tableta');
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
      await _button(tester, 'Crear tratamiento');
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

Future<void> _openCatalog(
  WidgetTester tester,
  FakeBackend backend, {
  double scale = 1,
}) async {
  tester.view.physicalSize = scale == 1
      ? const Size(393, 883)
      : const Size(360, 640);
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
        delete: DeleteMedication(backend),
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
        medications: medication,
      ),
      createManagementBloc: (_, _) => throw UnimplementedError(),
      createMyMedicationsBloc: () => throw UnimplementedError(),
    ),
  );
  await tester.pumpWidget(
    MaterialApp(
      theme: TataTheme.light,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
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
  }.entries) {
    await tester.enterText(find.byKey(Key(entry.key)), entry.value);
  }
  await _button(tester, 'Guardar medicamento');
}

/// Opens the actions menu of one medication card and picks [label].
Future<void> _action(
  WidgetTester tester,
  String medicationId,
  String label,
) async {
  final menu = find.byKey(Key('medication-actions-$medicationId'));
  await tester.ensureVisible(menu);
  await tester.pumpAndSettle();
  await tester.tap(menu);
  await tester.pumpAndSettle();
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}

Future<void> _button(WidgetTester tester, String text) async {
  final button = find.widgetWithText(ElevatedButton, text);
  await tester.ensureVisible(button);
  await tester.pumpAndSettle();
  await tester.tap(button);
  await tester.pumpAndSettle();
}
