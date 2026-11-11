import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tata/features/adherence_analytics/application/readmodels/adherence_period.dart';
import 'package:tata/features/adherence_analytics/presentation/bloc/history/history_state.dart';
import 'package:tata/features/adherence_analytics/presentation/screens/adherence_history_screen.dart';
import 'package:tata/shared/presentation/widgets/caregiver_tab_bar.dart';

import '../../support/visual_capture.dart';
import '../support/adherence_fixtures.dart';

void main() {
  setUpAll(loadTataFonts);

  Future<void> pumpScreen(
    WidgetTester tester,
    HistoryState state, {
    ValueChanged<AdherencePeriod>? onPeriod,
    VoidCallback? onRecommendations,
    VoidCallback? onRetry,
    ValueChanged<CaregiverTab>? onTab,
    Locale locale = const Locale('es'),
  }) async {
    final animated = state.status == HistoryStatus.loading;
    useFigmaPhone(tester);
    await tester.pumpWidget(
      RepaintBoundary(
        key: const Key('history-capture'),
        child: adherenceApp(
          AdherenceHistoryScreen(
            state: state,
            clock: () => fixtureNow,
            onPeriodSelected: onPeriod ?? (_) {},
            onOpenRecommendations: onRecommendations ?? () {},
            onRetry: onRetry ?? () {},
            onTabSelected: onTab ?? (_) {},
          ),
          locale: locale,
        ),
      ),
    );
    // The progress indicator of the loading card never stops animating.
    if (animated) {
      await tester.pump(const Duration(milliseconds: 100));
    } else {
      await tester.pumpAndSettle();
    }
  }

  HistoryState content({bool periodUpdated = false}) => HistoryState(
    status: HistoryStatus.content,
    summary: sampleSummary(),
    periodUpdated: periodUpdated,
  );

  testWidgets('draws the figures, trend, pattern and recent intakes', (
    tester,
  ) async {
    await pumpScreen(tester, content());
    await captureWidget(
      tester,
      find.byKey(const Key('history-capture')),
      'adherence-history-content',
    );

    expect(find.text('Historial e insights'), findsOneWidget);
    expect(find.text('Últimos 30 días ⌄'), findsOneWidget);
    expect(find.text('92%'), findsWidgets);
    expect(find.text('86%'), findsOneWidget);
    expect(find.text('6, 4'), findsOneWidget);
    expect(find.text('↑ 8% vs. 30 días previos'), findsOneWidget);
    expect(find.text('↑ 12%'), findsOneWidget);
    expect(find.text('últ. 30 días'), findsOneWidget);
    expect(find.text('Evolución de adherencia'), findsOneWidget);
    expect(find.text('Patrón detectado'), findsOneWidget);
    expect(find.text('Excelente progreso'), findsOneWidget);
    expect(
      find.text('4 omisiones y 6 tomas tardías se concentran en la tarde.'),
      findsOneWidget,
    );
    expect(find.text('Tomas recientes'), findsOneWidget);
    expect(find.text('Hoy, 8:00 a. m.'), findsOneWidget);
    expect(find.text('Losartán, a tiempo'), findsOneWidget);
    expect(find.text('Ayer, 8:00 p. m.'), findsOneWidget);
    expect(find.text('Amlodipino, 24 min tarde'), findsOneWidget);
    expect(find.text('Sáb, 1:00 p. m.'), findsOneWidget);
    expect(find.text('Vitamina D3, omitida'), findsOneWidget);
  });

  testWidgets('shows the latest trend value and five axis dates', (
    tester,
  ) async {
    await pumpScreen(tester, content());

    expect(find.text('92%\n10 nov'), findsOneWidget);
    for (final label in ['11 oct', '21 oct', '26 oct', '5 nov', '10 nov']) {
      expect(find.text(label), findsWidgets, reason: label);
    }
    for (final axis in ['100%', '75%', '50%', '25%', '0%']) {
      expect(find.text(axis), findsOneWidget);
    }
  });

  testWidgets('the content runs under the floating bar and ends clear of it', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(1179, 1800)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      adherenceApp(
        AdherenceHistoryScreen(
          state: content(),
          clock: () => fixtureNow,
          onPeriodSelected: (_) {},
          onOpenRecommendations: () {},
          onRetry: () {},
          onTabSelected: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    final barTop = tester.getTopLeft(find.byType(CaregiverTabBar)).dy;

    // Like Figma, the scrolling body is not cut where the bar starts.
    expect(
      tester.getBottomLeft(find.byType(SingleChildScrollView)).dy,
      greaterThan(barTop),
    );

    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -3000),
    );
    await tester.pumpAndSettle();

    final lastCardBottom = tester
        .getBottomLeft(find.text('Vitamina D3, omitida'))
        .dy;
    expect(lastCardBottom, lessThan(barTop), reason: 'last row hidden by bar');
  });

  testWidgets('the metric cards keep the Figma height, not a looser one', (
    tester,
  ) async {
    await pumpScreen(tester, content());

    final card = find.ancestor(
      of: find.text('Adherencia'),
      matching: find.byType(Container),
    );
    // Figma: 92. The two-line caption may add a little; 1.43 line height gave 115.
    expect(tester.getSize(card.first).height, inInclusiveRange(92, 104));
  });

  testWidgets('omits what the server did not send', (tester) async {
    await pumpScreen(
      tester,
      HistoryState(
        status: HistoryStatus.content,
        summary: sampleSummary(
          adherenceChange: null,
          onTimeChange: null,
          withPattern: false,
        ),
      ),
    );

    expect(find.textContaining('vs.'), findsNothing);
    expect(find.text('Patrón detectado'), findsNothing);
    expect(find.text('últ. 30 días'), findsOneWidget);
  });

  testWidgets('a lower adherence asks for attention instead of praise', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      HistoryState(
        status: HistoryStatus.content,
        summary: sampleSummary(adherencePercent: 70),
      ),
    );

    expect(find.text('Atención a los horarios'), findsOneWidget);
    expect(find.text('Excelente progreso'), findsNothing);
  });

  testWidgets('the period menu offers seven and thirty days', (tester) async {
    AdherencePeriod? selected;
    await pumpScreen(tester, content(), onPeriod: (p) => selected = p);

    await tester.tap(find.text('Últimos 30 días ⌄'));
    await tester.pumpAndSettle();
    expect(find.text('Últimos 7 días'), findsOneWidget);
    await tester.tap(find.text('Últimos 7 días'));
    await tester.pumpAndSettle();

    expect(selected, AdherencePeriod.lastWeek);
  });

  testWidgets('the pattern card and the bottom bar are actionable', (
    tester,
  ) async {
    var recommendations = 0;
    CaregiverTab? tab;
    await pumpScreen(
      tester,
      content(),
      onRecommendations: () => recommendations++,
      onTab: (t) => tab = t,
    );

    await tester.tap(find.text('Ver recomendaciones  ›'));
    await tester.tap(find.text('Alertas'));

    expect(recommendations, 1);
    expect(tab, CaregiverTab.alerts);
  });

  testWidgets('a selected period without intakes reads as no results', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      const HistoryState(
        status: HistoryStatus.noResults,
        period: AdherencePeriod.lastWeek,
      ),
    );
    await captureWidget(
      tester,
      find.byKey(const Key('history-capture')),
      'adherence-history-no-results',
    );

    expect(find.text('Últimos 7 días ⌄'), findsOneWidget);
    expect(find.text('Sin resultados'), findsOneWidget);
    expect(
      find.text(
        'No existen tomas registradas dentro del período seleccionado.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('a first load without intakes reads as insufficient data', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      const HistoryState(status: HistoryStatus.insufficientData),
    );
    await captureWidget(
      tester,
      find.byKey(const Key('history-capture')),
      'adherence-history-insufficient-data',
    );

    expect(find.text('Sin datos suficientes'), findsOneWidget);
    expect(
      find.text('No existen tomas en este período para calcular adherencia.'),
      findsOneWidget,
    );
  });

  testWidgets('shows the period notice only after a user selection', (
    tester,
  ) async {
    await pumpScreen(tester, content(periodUpdated: true));
    expect(find.text('Período actualizado'), findsOneWidget);

    await pumpScreen(tester, content());
    expect(find.text('Período actualizado'), findsNothing);
  });

  testWidgets('loading and failure keep the bottom bar and offer a retry', (
    tester,
  ) async {
    var retries = 0;
    await pumpScreen(tester, const HistoryState());
    expect(find.text('Consultando tu historial…'), findsOneWidget);

    await pumpScreen(
      tester,
      const HistoryState(
        status: HistoryStatus.failure,
        errorCode: 'NETWORK_UNAVAILABLE',
      ),
      onRetry: () => retries++,
    );
    expect(find.text('No pudimos cargar el historial'), findsOneWidget);
    expect(find.text('No hay conexión. Inténtalo nuevamente.'), findsOneWidget);
    expect(find.text('Inicio'), findsOneWidget);

    await tester.tap(find.text('Reintentar'));
    expect(retries, 1);
  });

  testWidgets('failure codes never expose provider text', (tester) async {
    for (final (code, message) in [
      ('ACCESS_DENIED', 'No tienes permiso para realizar esta acción.'),
      ('RATE_LIMITED', 'Espera un momento antes de volver a intentarlo.'),
      ('INVALID_RESPONSE', 'Inténtalo nuevamente en unos minutos.'),
    ]) {
      await pumpScreen(
        tester,
        HistoryState(status: HistoryStatus.failure, errorCode: code),
      );
      expect(find.text(message), findsOneWidget, reason: code);
    }
  });

  testWidgets('keeps every control reachable at 150 percent text', (
    tester,
  ) async {
    useFigmaPhone(tester);
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          size: Size(393, 883),
          textScaler: TextScaler.linear(1.5),
        ),
        child: adherenceApp(
          AdherenceHistoryScreen(
            state: content(),
            clock: () => fixtureNow,
            onPeriodSelected: (_) {},
            onOpenRecommendations: () {},
            onRetry: () {},
            onTabSelected: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Historial e insights'), findsOneWidget);
  });

  testWidgets('speaks English with plurals and the 12-hour clock', (
    tester,
  ) async {
    await pumpScreen(tester, content(), locale: const Locale('en'));

    expect(find.text('History & insights'), findsOneWidget);
    expect(find.text('Last 30 days ⌄'), findsOneWidget);
    expect(find.text('↑ 8% vs. previous 30 days'), findsOneWidget);
    expect(
      find.text('4 omissions and 6 late intakes concentrate in the afternoon.'),
      findsOneWidget,
    );
    expect(find.text('Today, 8:00 AM'), findsOneWidget);
    expect(find.text('Losartán, on time'), findsOneWidget);
  });
}
