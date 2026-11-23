import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tata/app/integration/caregiver_adherence_entry.dart';
import 'package:tata/app/integration/caregiver_treatment_entry.dart';
import 'package:tata/features/adherence_analytics/application/ports/adherence_reader.dart';
import 'package:tata/features/adherence_analytics/application/ports/recommendations_reader.dart';
import 'package:tata/features/adherence_analytics/application/readmodels/adherence_recommendation.dart';
import 'package:tata/features/adherence_analytics/application/readmodels/adherence_summary.dart';
import 'package:tata/features/adherence_analytics/application/usecases/get_adherence_summary.dart';
import 'package:tata/features/adherence_analytics/application/usecases/get_recommendations.dart';
import 'package:tata/features/adherence_analytics/presentation/bloc/history/history_bloc.dart';
import 'package:tata/features/adherence_analytics/presentation/bloc/recommendations/recommendations_bloc.dart';
import 'package:tata/features/care_link/application/readmodels/caregiver_link_summary.dart';
import 'package:tata/features/treatment_management/application/readmodels/treatment_detail.dart';
import 'package:tata/features/treatment_management/application/usecases/list_treatments.dart';
import 'package:tata/features/treatment_management/domain/value_objects/treatment_status.dart';
import 'package:tata/features/treatment_management/presentation/bloc/treatment_list/treatment_list_bloc.dart';
import 'package:tata/features/treatment_management/presentation/navigation/treatment_navigation.dart';
import 'package:tata/l10n/generated/app_localizations.dart';
import 'package:tata/shared/common/result/app_result.dart';
import 'package:tata/shared/presentation/theme/tata_theme.dart';

import '../adherence_analytics/support/adherence_fixtures.dart';
import '../support/fake_treatment_backend.dart';
import '../treatment_management/treatment_blocs_test.dart'
    show FakeReader, managementBloc;

final class _Analytics implements AdherenceReader, RecommendationsReader {
  @override
  Future<AppResult<AdherenceSummary?>> summary(
    String id,
    int days, {
    String? treatmentId,
  }) async {
    expect(id, 'adult-A');
    return AppSuccess(sampleSummary(periodDays: days));
  }

  @override
  Future<AppResult<AdherenceInsight?>> insight(String id, int days) async {
    expect(id, 'adult-A');
    return AppSuccess(sampleInsight());
  }
}

void main() {
  testWidgets(
    'apply starts a scoped treatment review and changes reminders only after Save',
    (tester) async {
      final (backend, _) = await _begin(tester);
      await _reachTreatments(tester);
      expect(backend.configureCalls, 0);
      await tester.tap(find.text('Control de presión'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Editar pauta'));
      await tester.pumpAndSettle();
      final lead = find.byKey(const Key('edit-lead'));
      await tester.ensureVisible(lead);
      await tester.pumpAndSettle();
      expect(tester.widget<TextFormField>(lead).controller!.text, '0');
      await tester.enterText(lead, '15');
      expect(backend.configureCalls, 0);
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();
      expect(backend.configureCalls, 1);
      expect(backend.stored!.reminderLeadMinutes, 15);
      expect(backend.stored!.dose, '1 comprimido');
      expect(backend.stored!.status, TreatmentStatus.active);
      expect(backend.stored!.recurrenceZone, 'America/Lima');
      expect(find.text('Cambios guardados'), findsOneWidget);
      expect(find.textContaining('15 min antes'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'a rejected session exits the review without refreshing a closed treatment list',
    (tester) async {
      final (backend, invalidations) = await _begin(tester);
      await _reachTreatments(tester);
      backend.failure = 'AUTHENTICATION_REQUIRED';
      await tester.tap(find.text('Control de presión'));
      await tester.pumpAndSettle();
      expect(invalidations, [true]);
      expect(find.text('Historial'), findsOneWidget);
      expect(find.text('Control de presión'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}

Future<void> _reachTreatments(WidgetTester tester) async {
  await tester.tap(find.text('Historial'));
  await tester.pumpAndSettle();
  final recommendations = find.textContaining('Ver recomendaciones');
  await tester.ensureVisible(recommendations);
  await tester.pumpAndSettle();
  await tester.tap(recommendations);
  await tester.pumpAndSettle();
  await tester.tap(find.text('Aplicar ajustes'));
  await tester.pumpAndSettle();
  expect(find.text('Tratamientos'), findsOneWidget);
}

Future<(FakeBackend, List<bool>)> _begin(WidgetTester tester) async {
  tester.view.physicalSize = const Size(393, 883);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final backend = FakeBackend()
    ..stored = const TreatmentDetail(
      id: 'tr-1',
      olderAdultId: 'adult-A',
      name: 'Control de presión',
      status: TreatmentStatus.active,
      medicationId: 'med-1',
      dose: '1 comprimido',
      frequency: 'Cada día',
      scheduledTimes: ['08:00'],
      instructions: 'Con agua',
      reminderLeadMinutes: 0,
      followUpDelayMinutes: 10,
      recurrenceZone: 'America/Lima',
    );
  final analytics = _Analytics();
  final invalidations = <bool>[];
  void invalidated() => invalidations.add(true);
  final treatments = TreatmentNavigation(
    TreatmentFactories(
      createListBloc: (adult) {
        expect(adult, 'adult-A');
        return TreatmentListBloc(
          list: ListTreatments(FakeReader(backend)),
          olderAdultId: adult,
        );
      },
      createManagementBloc: (treatment, adult) {
        expect(treatment, 'tr-1');
        expect(adult, 'adult-A');
        return managementBloc(backend);
      },
      createRegistrationBloc: (_) => throw UnimplementedError(),
      createMedicationsBloc: (_) => throw UnimplementedError(),
      createSetupBloc: (_, _) => throw UnimplementedError(),
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
            child: const Text('Historial'),
            onPressed: () => openAdherenceFlow(
              context,
              link: CaregiverLinkSummary(
                id: 'link-A',
                olderAdultId: 'adult-A',
                fullName: 'Rosa Vargas',
                confirmedAt: DateTime(2026, 10, 27),
              ),
              createHistoryBloc: (adult) => HistoryBloc(
                olderAdultId: adult,
                summary: GetAdherenceSummary(analytics),
              ),
              createRecommendationsBloc: (adult) => RecommendationsBloc(
                olderAdultId: adult,
                recommendations: GetRecommendations(analytics),
              ),
              onSessionInvalidated: invalidated,
              onApplyAdjustments: () => openCaregiverTreatments(
                context,
                olderAdultId: 'adult-A',
                personName: 'Rosa Vargas',
                treatments: treatments,
                onSessionInvalidated: invalidated,
              ),
            ),
          ),
        ),
      ),
    ),
  );
  return (backend, invalidations);
}
