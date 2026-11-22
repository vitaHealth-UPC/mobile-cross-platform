import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tata/features/adherence_analytics/presentation/bloc/history/history_state.dart';
import 'package:tata/features/adherence_analytics/presentation/bloc/recommendations/recommendations_state.dart';
import 'package:tata/features/adherence_analytics/presentation/screens/adherence_history_screen.dart';
import 'package:tata/features/adherence_analytics/presentation/screens/adherence_recommendations_screen.dart';
import 'package:tata/l10n/generated/app_localizations.dart';
import 'package:tata/shared/presentation/theme/tata_theme.dart';

import '../../support/visual_capture.dart';
import '../support/adherence_fixtures.dart';

/// Checks the recommendation content and both legitimate empty-result variants.
void main() {
  setUpAll(loadTataFonts);
  for (final variant in ['recommendations', 'insufficient', 'empty-history']) {
    for (final scale in [1.0, 1.5]) {
      testWidgets('$variant renders with text scale $scale', (tester) async {
        tester.view.physicalSize = scale == 1
            ? const Size(393, 883)
            : const Size(360, 640);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        var applied = 0;
        var back = 0;
        final screen = variant == 'empty-history'
            ? AdherenceHistoryScreen(
                state: const HistoryState(status: HistoryStatus.noResults),
                onPeriodSelected: (_) {},
                onOpenRecommendations: () {},
                onRetry: () {},
                onTabSelected: (_) {},
              )
            : AdherenceRecommendationsScreen(
                state: variant == 'recommendations'
                    ? RecommendationsState(
                        status: RecommendationsStatus.content,
                        insight: sampleInsight(),
                      )
                    : const RecommendationsState(
                        status: RecommendationsStatus.insufficientEvidence,
                      ),
                onBackToHistory: () => back++,
                onRetry: () {},
                onTabSelected: (_) {},
                onApplyAdjustments: () => applied++,
              );
        await tester.pumpWidget(
          MaterialApp(
            theme: TataTheme.light,
            locale: const Locale('es'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(scale)),
              child: RepaintBoundary(
                key: const Key('analytics-empty-capture'),
                child: child!,
              ),
            ),
            home: screen,
          ),
        );
        await tester.pumpAndSettle();
        if (variant == 'recommendations') {
          expect(find.text('Aplicar ajustes'), findsOneWidget);
        } else if (variant == 'insufficient') {
          expect(find.text('Evidencia insuficiente'), findsOneWidget);
          expect(find.text('Aplicar ajustes'), findsNothing);
        } else {
          expect(find.text('Sin resultados'), findsOneWidget);
          expect(find.text('92%'), findsNothing);
        }
        await captureWidget(
          tester,
          find.byKey(const Key('analytics-empty-capture')),
          '$variant-$scale-top',
        );
        if (variant == 'recommendations' && scale > 1) {
          await tester.ensureVisible(
            find.text('3. Acompaña durante una semana'),
          );
          await tester.pumpAndSettle();
          await captureWidget(
            tester,
            find.byKey(const Key('analytics-empty-capture')),
            '$variant-$scale-cards',
          );
        }
        if (variant != 'empty-history') {
          final action = find.text(
            variant == 'recommendations'
                ? 'Aplicar ajustes'
                : 'Volver a historial',
          );
          await tester.ensureVisible(action);
          await tester.pumpAndSettle();
          if (scale > 1) {
            await captureWidget(
              tester,
              find.byKey(const Key('analytics-empty-capture')),
              '$variant-$scale-action',
            );
          }
          await tester.tap(action);
          await tester.pumpAndSettle();
          expect(applied, variant == 'recommendations' ? 1 : 0);
          expect(back, variant == 'insufficient' ? 1 : 0);
        }
        expect(tester.takeException(), isNull);
      });
    }
  }
}
