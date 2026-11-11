import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tata/app/integration/caregiver_adherence_entry.dart';
import 'package:tata/features/adherence_analytics/application/ports/adherence_reader.dart';
import 'package:tata/features/adherence_analytics/application/ports/recommendations_reader.dart';
import 'package:tata/features/adherence_analytics/application/readmodels/adherence_recommendation.dart';
import 'package:tata/features/adherence_analytics/application/readmodels/adherence_summary.dart';
import 'package:tata/features/adherence_analytics/application/usecases/get_adherence_summary.dart';
import 'package:tata/features/adherence_analytics/application/usecases/get_recommendations.dart';
import 'package:tata/features/adherence_analytics/presentation/bloc/history/history_bloc.dart';
import 'package:tata/features/adherence_analytics/presentation/bloc/recommendations/recommendations_bloc.dart';
import 'package:tata/features/care_link/application/readmodels/caregiver_link_summary.dart';
import 'package:tata/features/care_link/presentation/screens/caregiver_profiles_screen.dart';
import 'package:tata/shared/common/result/app_result.dart';

import '../adherence_analytics/support/adherence_fixtures.dart';
import '../support/visual_capture.dart';

/// Test double serving both readers and recording who was asked.
final class _Readers implements AdherenceReader, RecommendationsReader {
  _Readers({this.summaryResult});

  final AppResult<AdherenceSummary?>? summaryResult;
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
    return AppSuccess(sampleInsight());
  }
}

void main() {
  setUpAll(loadTataFonts);

  final link = CaregiverLinkSummary(
    id: 'link-A',
    olderAdultId: 'adult-A',
    fullName: 'Rosa Vargas',
    confirmedAt: DateTime.utc(2026, 10, 27),
  );

  Future<void> pumpCaregiverArea(
    WidgetTester tester,
    _Readers readers, {
    bool withEntry = true,
    VoidCallback? onInvalidated,
  }) async {
    useFigmaPhone(tester);
    await tester.pumpWidget(
      adherenceApp(
        Builder(
          builder: (context) => CaregiverProfilesScreen(
            links: [link],
            loading: false,
            onRegister: (_, _) {},
            onRefresh: () {},
            onSignOut: () {},
            onOpenProfile: withEntry
                ? (selected) => openAdherenceFlow(
                    context,
                    link: selected,
                    createHistoryBloc: (id) => HistoryBloc(
                      olderAdultId: id,
                      summary: GetAdherenceSummary(readers),
                    ),
                    createRecommendationsBloc: (id) => RecommendationsBloc(
                      olderAdultId: id,
                      recommendations: GetRecommendations(readers),
                    ),
                    onSessionInvalidated: onInvalidated ?? () {},
                  )
                : null,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('without an entry the profiles are not actionable', (
    tester,
  ) async {
    final readers = _Readers();
    await pumpCaregiverArea(tester, readers, withEntry: false);

    expect(find.byIcon(Icons.chevron_right), findsNothing);
    await tester.tap(find.text('Rosa Vargas'));
    await tester.pumpAndSettle();

    expect(find.text('Historial e insights'), findsNothing);
    expect(readers.summaryRequests, isEmpty);
  });

  testWidgets('a confirmed profile opens the history of its adult', (
    tester,
  ) async {
    final readers = _Readers();
    await pumpCaregiverArea(tester, readers);
    expect(find.byIcon(Icons.chevron_right), findsOneWidget);

    await tester.tap(find.text('Rosa Vargas'));
    await tester.pumpAndSettle();

    expect(find.text('Historial e insights'), findsOneWidget);
    expect(find.text('Excelente progreso'), findsOneWidget);
    expect(readers.summaryRequests, [('adult-A', 30)]);
  });

  testWidgets('the recommendations are one step further and the back returns', (
    tester,
  ) async {
    final readers = _Readers();
    await pumpCaregiverArea(tester, readers);
    await tester.tap(find.text('Rosa Vargas'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Ver recomendaciones  ›'));
    await tester.pumpAndSettle();
    expect(find.text('1. Ajusta el recordatorio'), findsOneWidget);
    expect(readers.insightRequests, [('adult-A', 30)]);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Historial e insights'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Rosa Vargas'), findsOneWidget);
  });

  testWidgets('any bottom tab returns to the caregiver area', (tester) async {
    final readers = _Readers();
    await pumpCaregiverArea(tester, readers);
    await tester.tap(find.text('Rosa Vargas'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ver recomendaciones  ›'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Persona'));
    await tester.pumpAndSettle();

    expect(find.text('Rosa Vargas'), findsOneWidget);
    expect(find.text('Recomendaciones'), findsNothing);
    expect(find.text('Historial e insights'), findsNothing);
  });

  testWidgets('a rejected credential closes the flow and reaches the host', (
    tester,
  ) async {
    var invalidated = 0;
    await pumpCaregiverArea(
      tester,
      _Readers(summaryResult: const AppFailure('AUTHENTICATION_REQUIRED')),
      onInvalidated: () => invalidated++,
    );

    await tester.tap(find.text('Rosa Vargas'));
    await tester.pumpAndSettle();

    expect(invalidated, 1);
    expect(find.text('Rosa Vargas'), findsOneWidget);
    expect(find.text('Historial e insights'), findsNothing);
  });
}
