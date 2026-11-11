import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tata/features/adherence_analytics/application/readmodels/adherence_recommendation.dart';
import 'package:tata/features/adherence_analytics/presentation/bloc/recommendations/recommendations_state.dart';
import 'package:tata/features/adherence_analytics/presentation/screens/adherence_recommendations_screen.dart';
import 'package:tata/shared/presentation/widgets/caregiver_tab_bar.dart';

import '../../support/visual_capture.dart';
import '../support/adherence_fixtures.dart';

void main() {
  setUpAll(loadTataFonts);

  Future<void> pumpScreen(
    WidgetTester tester,
    RecommendationsState state, {
    VoidCallback? onBack,
    VoidCallback? onRetry,
    VoidCallback? onApply,
    ValueChanged<CaregiverTab>? onTab,
    Locale locale = const Locale('es'),
  }) async {
    final animated = state.status == RecommendationsStatus.loading;
    useFigmaPhone(tester);
    await tester.pumpWidget(
      RepaintBoundary(
        key: const Key('recommendations-capture'),
        child: adherenceApp(
          AdherenceRecommendationsScreen(
            state: state,
            onBackToHistory: onBack ?? () {},
            onRetry: onRetry ?? () {},
            onTabSelected: onTab ?? (_) {},
            onApplyAdjustments: onApply,
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

  RecommendationsState content({AdherenceInsight? insight}) =>
      RecommendationsState(
        status: RecommendationsStatus.content,
        insight: insight ?? sampleInsight(),
      );

  testWidgets('draws the pattern, the heat map and the three actions', (
    tester,
  ) async {
    await pumpScreen(tester, content(), onApply: () {});
    await captureWidget(
      tester,
      find.byKey(const Key('recommendations-capture')),
      'adherence-recommendations-content',
    );

    expect(find.text('Recomendaciones'), findsOneWidget);
    expect(
      find.text('Basadas en patrones de los últimos 30 días.'),
      findsOneWidget,
    );
    expect(find.text('Patrón de omisiones por la tarde'), findsOneWidget);
    expect(
      find.text(
        '4 omisiones y 6 tomas tardías se concentran entre 6:00 y 9:00 p. m.',
      ),
      findsOneWidget,
    );
    expect(find.text('Concentración por horario'), findsOneWidget);
    expect(find.text('1. Ajusta el recordatorio'), findsOneWidget);
    expect(
      find.text('Prueba avisar 15 minutos antes de la toma.'),
      findsOneWidget,
    );
    expect(find.text('2. Revisa el horario'), findsOneWidget);
    expect(find.text('3. Acompaña durante una semana'), findsOneWidget);
    expect(find.text('Aplicar ajustes'), findsOneWidget);
  });

  testWidgets('the cards keep the Figma heights and spacing', (tester) async {
    await pumpScreen(tester, content());

    final pattern = find.ancestor(
      of: find.text('Concentración por horario'),
      matching: find.byType(Container),
    );
    final first = find.ancestor(
      of: find.text('1. Ajusta el recordatorio'),
      matching: find.byType(Container),
    );
    final second = find.ancestor(
      of: find.text('2. Revisa el horario'),
      matching: find.byType(Container),
    );
    // Figma: pattern 182 tall, recommendations 71 tall and 14 apart.
    expect(tester.getSize(pattern.last).height, inInclusiveRange(180, 190));
    expect(tester.getSize(first.first).height, inInclusiveRange(69, 76));
    expect(
      tester.getTopLeft(second.first).dy - tester.getBottomLeft(first.first).dy,
      closeTo(14, 1),
    );
  });

  testWidgets('the heat map draws three rows of seven cells by intensity', (
    tester,
  ) async {
    await pumpScreen(tester, content());

    final cells = tester
        .widgetList<Container>(
          find.byWidgetPredicate(
            (w) =>
                w is Container &&
                w.constraints?.maxHeight == 7 &&
                w.decoration is BoxDecoration,
          ),
        )
        .toList();

    expect(cells, hasLength(21));
    final first = (cells.first.decoration! as BoxDecoration).color!;
    final strongest = (cells[5].decoration! as BoxDecoration).color!;
    expect(first.a, closeTo(0.27, 0.01));
    expect(strongest.a, closeTo(0.8, 0.01));
  });

  testWidgets('a lateness pattern and a split day period are worded', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      content(
        insight: sampleInsight(
          type: AdherencePatternType.lateness,
          fromHour: 11,
          toHour: 14,
        ),
      ),
    );

    expect(find.text('Patrón de tardanzas por la tarde'), findsOneWidget);
    expect(
      find.text(
        '4 omisiones y 6 tomas tardías se concentran entre 11:00 a. m. y 2:00 p. m.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('a night range that crosses midnight keeps both suffixes', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      content(insight: sampleInsight(fromHour: 22, toHour: 24)),
    );

    expect(
      find.text(
        '4 omisiones y 6 tomas tardías se concentran entre 10:00 p. m. y 12:00 a. m.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('shows only the actions the client knows', (tester) async {
    await pumpScreen(
      tester,
      content(
        insight: sampleInsight(
          recommendations: const [AdherenceRecommendation.reviewSchedule],
        ),
      ),
    );

    expect(find.text('1. Revisa el horario'), findsOneWidget);
    expect(find.textContaining('2.'), findsNothing);
  });

  testWidgets('the apply button needs a destination and then reports a tap', (
    tester,
  ) async {
    await pumpScreen(tester, content());
    expect(find.text('Aplicar ajustes'), findsNothing);

    var applied = 0;
    await pumpScreen(tester, content(), onApply: () => applied++);
    await tester.tap(find.text('Aplicar ajustes'));

    expect(applied, 1);
  });

  testWidgets('insufficient evidence explains itself and returns to history', (
    tester,
  ) async {
    var back = 0;
    await pumpScreen(
      tester,
      const RecommendationsState(
        status: RecommendationsStatus.insufficientEvidence,
      ),
      onBack: () => back++,
      onApply: () {},
    );
    await captureWidget(
      tester,
      find.byKey(const Key('recommendations-capture')),
      'adherence-recommendations-insufficient',
    );

    expect(find.text('Evidencia insuficiente'), findsOneWidget);
    expect(
      find.text(
        'Todavía no hay datos suficientes para presentar una recomendación concluyente.',
      ),
      findsOneWidget,
    );
    expect(find.text('Aplicar ajustes'), findsNothing);
    // A custom button style once dropped the theme font and showed system text.
    final label = tester.element(find.text('Volver a historial'));
    expect(DefaultTextStyle.of(label).style.fontFamily, 'Inter');

    await tester.tap(find.text('Volver a historial'));
    expect(back, 1);
  });

  testWidgets('loading and failure keep the bottom bar', (tester) async {
    var retries = 0;
    CaregiverTab? tab;
    await pumpScreen(tester, const RecommendationsState());
    expect(find.text('Consultando tus recomendaciones…'), findsOneWidget);

    await pumpScreen(
      tester,
      const RecommendationsState(
        status: RecommendationsStatus.failure,
        errorCode: 'ACCESS_DENIED',
      ),
      onRetry: () => retries++,
      onTab: (t) => tab = t,
    );
    expect(find.text('No pudimos cargar las recomendaciones'), findsOneWidget);
    expect(
      find.text('No tienes permiso para realizar esta acción.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Reintentar'));
    await tester.tap(find.text('Notas'));
    expect(retries, 1);
    expect(tab, CaregiverTab.notes);
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
          AdherenceRecommendationsScreen(
            state: content(),
            onBackToHistory: () {},
            onRetry: () {},
            onTabSelected: (_) {},
            onApplyAdjustments: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Aplicar ajustes'), findsOneWidget);
  });

  testWidgets('speaks English with its own pattern wording', (tester) async {
    await pumpScreen(tester, content(), locale: const Locale('en'));

    expect(find.text('Recommendations'), findsOneWidget);
    expect(find.text('Omission pattern in the afternoon'), findsOneWidget);
    expect(
      find.text(
        '4 omissions and 6 late intakes concentrate between 6:00 and 9:00 PM.',
      ),
      findsOneWidget,
    );
    expect(find.text('1. Adjust the reminder'), findsOneWidget);
  });
}
