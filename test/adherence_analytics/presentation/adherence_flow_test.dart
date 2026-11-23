import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tata/features/adherence_analytics/application/ports/adherence_reader.dart';
import 'package:tata/features/adherence_analytics/application/ports/recommendations_reader.dart';
import 'package:tata/features/adherence_analytics/application/readmodels/adherence_recommendation.dart';
import 'package:tata/features/adherence_analytics/application/readmodels/adherence_summary.dart';
import 'package:tata/features/adherence_analytics/application/usecases/get_adherence_summary.dart';
import 'package:tata/features/adherence_analytics/application/usecases/get_recommendations.dart';
import 'package:tata/features/adherence_analytics/presentation/bloc/history/history_bloc.dart';
import 'package:tata/features/adherence_analytics/presentation/bloc/recommendations/recommendations_bloc.dart';
import 'package:tata/features/adherence_analytics/presentation/navigation/adherence_flow_route.dart';
import 'package:tata/shared/common/result/app_result.dart';
import 'package:tata/shared/presentation/widgets/caregiver_tab_bar.dart';

import '../../support/visual_capture.dart';
import '../support/adherence_fixtures.dart';

/// Test double that serves both readers and records who was asked.
final class _Readers implements AdherenceReader, RecommendationsReader {
  _Readers({this.summaryResult, this.insightResult});

  AppResult<AdherenceSummary?>? summaryResult;
  AppResult<AdherenceInsight?>? insightResult;
  final summaryRequests = <(String, int)>[];
  final insightRequests = <(String, int)>[];

  @override
  Future<AppResult<AdherenceSummary?>> summary(
    String olderAdultId,
    int periodDays,
  ) async {
    summaryRequests.add((olderAdultId, periodDays));
    return summaryResult ?? AppSuccess(sampleSummary(periodDays: periodDays));
  }

  @override
  Future<AppResult<AdherenceInsight?>> insight(
    String olderAdultId,
    int periodDays,
  ) async {
    insightRequests.add((olderAdultId, periodDays));
    return insightResult ?? AppSuccess(sampleInsight());
  }
}

void main() {
  setUpAll(loadTataFonts);

  Future<void> pumpFlow(
    WidgetTester tester,
    _Readers readers, {
    ValueChanged<CaregiverTab>? onTab,
    VoidCallback? onInvalidated,
    VoidCallback? onApply,
  }) async {
    useFigmaPhone(tester);
    await tester.pumpWidget(
      adherenceApp(
        AdherenceFlowRoute(
          olderAdultId: 'adult-A',
          clock: () => fixtureNow,
          createHistoryBloc: (id) => HistoryBloc(
            olderAdultId: id,
            summary: GetAdherenceSummary(readers),
          ),
          createRecommendationsBloc: (id) => RecommendationsBloc(
            olderAdultId: id,
            recommendations: GetRecommendations(readers),
          ),
          onTabSelected: onTab ?? (_) {},
          onSessionInvalidated: onInvalidated ?? () {},
          onApplyAdjustments: onApply,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('opens the history of the adult for thirty days', (tester) async {
    final readers = _Readers();

    await pumpFlow(tester, readers);

    expect(find.text('Historial e insights'), findsOneWidget);
    expect(find.text('Excelente progreso'), findsOneWidget);
    expect(readers.summaryRequests, [('adult-A', 30)]);
    expect(readers.insightRequests, isEmpty);
  });

  testWidgets('the recommendations open on top and the back gesture returns', (
    tester,
  ) async {
    final readers = _Readers();
    await pumpFlow(tester, readers);

    await tester.tap(find.text('Ver recomendaciones  ›'));
    await tester.pumpAndSettle();

    expect(find.text('Recomendaciones'), findsOneWidget);
    expect(find.text('1. Ajusta el recordatorio'), findsOneWidget);
    expect(readers.insightRequests, [('adult-A', 30)]);

    // The Figma frames have no app bar: the system back gesture closes it.
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('Historial e insights'), findsOneWidget);
    expect(find.text('Recomendaciones'), findsNothing);
  });

  testWidgets('"Volver a historial" pops the recommendations', (tester) async {
    final readers = _Readers(insightResult: const AppSuccess(null));
    await pumpFlow(tester, readers);
    await tester.tap(find.text('Ver recomendaciones  ›'));
    await tester.pumpAndSettle();
    expect(find.text('Evidencia insuficiente'), findsOneWidget);

    await tester.tap(find.text('Volver a historial'));
    await tester.pumpAndSettle();

    expect(find.text('Historial e insights'), findsOneWidget);
  });

  testWidgets('the apply button follows the host callback', (tester) async {
    var applied = 0;
    await pumpFlow(tester, _Readers(), onApply: () => applied++);
    await tester.tap(find.text('Ver recomendaciones  ›'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Aplicar ajustes'));

    expect(applied, 1);
  });

  testWidgets('the host receives the tab chosen on either screen', (
    tester,
  ) async {
    final tabs = <CaregiverTab>[];
    await pumpFlow(tester, _Readers(), onTab: tabs.add);

    await tester.tap(find.text('Alertas'));
    await tester.tap(find.text('Ver recomendaciones  ›'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Persona'));

    expect(tabs, [CaregiverTab.alerts, CaregiverTab.person]);
  });

  testWidgets('a lost session is reported to the host, not shown as an error', (
    tester,
  ) async {
    var invalidated = 0;
    await pumpFlow(
      tester,
      _Readers(summaryResult: const AppFailure('AUTHENTICATION_REQUIRED')),
      onInvalidated: () => invalidated++,
    );

    expect(invalidated, 1);
  });

  testWidgets('a withdrawn consent stays on screen as an access message', (
    tester,
  ) async {
    var invalidated = 0;
    await pumpFlow(
      tester,
      _Readers(summaryResult: const AppFailure('ACCESS_DENIED')),
      onInvalidated: () => invalidated++,
    );

    expect(invalidated, 0);
    expect(
      find.text('No tienes permiso para realizar esta acción.'),
      findsOneWidget,
    );
  });
}
