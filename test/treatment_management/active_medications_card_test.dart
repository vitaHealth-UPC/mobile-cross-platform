import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tata/features/treatment_management/application/usecases/deactivate_medication.dart';
import 'package:tata/features/treatment_management/application/usecases/delete_medication.dart';
import 'package:tata/features/treatment_management/application/usecases/list_medications.dart';
import 'package:tata/features/treatment_management/application/usecases/reactivate_medication.dart';
import 'package:tata/features/treatment_management/application/usecases/update_medication.dart';
import 'package:tata/features/treatment_management/domain/entities/medication.dart';
import 'package:tata/features/treatment_management/presentation/bloc/medication_management/medication_management_bloc.dart';
import 'package:tata/features/treatment_management/presentation/widgets/active_medications_card.dart';
import 'package:tata/l10n/generated/app_localizations.dart';
import 'package:tata/shared/presentation/theme/tata_theme.dart';

import '../support/fake_treatment_backend.dart';

void main() {
  Future<int> pump(WidgetTester tester, FakeBackend backend) async {
    var invalidated = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: TataTheme.light,
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ActiveMedicationsCard(
            createBloc: () => MedicationManagementBloc(
              list: ListMedications(backend),
              update: UpdateMedication(backend),
              deactivate: DeactivateMedication(backend),
              delete: DeleteMedication(backend),
              reactivate: ReactivateMedication(backend),
              olderAdultId: 'adult-A',
            ),
            onSessionInvalidated: () => invalidated++,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return invalidated;
  }

  testWidgets('lists only active medications with their strength', (
    tester,
  ) async {
    final backend = FakeBackend();
    backend.medications
      ..['med-2'] = Medication(
        id: 'med-2',
        olderAdultId: 'adult-A',
        name: 'Losartán',
        presentation: '50 mg, tableta',
        active: true,
      )
      ..['med-3'] = Medication(
        id: 'med-3',
        olderAdultId: 'adult-A',
        name: 'Atorvastatina',
        presentation: '20 mg',
        active: false,
      );
    await pump(tester, backend);
    expect(find.text('Tratamiento actual'), findsOneWidget);
    expect(find.text('2 medicamentos activos'), findsOneWidget);
    expect(find.text('Metformina 500 mg'), findsOneWidget);
    expect(find.text('Losartán 50 mg'), findsOneWidget);
    expect(find.textContaining('Atorvastatina'), findsNothing);
  });

  testWidgets('no active medication is said, not left blank', (tester) async {
    await pump(tester, FakeBackend()..medications.clear());
    expect(find.text('Sin medicamentos activos'), findsOneWidget);
  });

  testWidgets('a lost session is reported to the host', (tester) async {
    final lost = FakeBackend()..failure = 'AUTHENTICATION_REQUIRED';
    expect(await pump(tester, lost), 1);
    expect(find.text('No pudimos cargar la medicación.'), findsOneWidget);
  });
}
