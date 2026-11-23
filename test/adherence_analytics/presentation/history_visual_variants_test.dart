import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tata/features/adherence_analytics/application/ports/adherence_reader.dart';
import 'package:tata/features/adherence_analytics/application/readmodels/adherence_summary.dart';
import 'package:tata/features/adherence_analytics/application/readmodels/adherence_trend_point.dart';
import 'package:tata/features/adherence_analytics/application/usecases/get_adherence_summary.dart';
import 'package:tata/features/adherence_analytics/presentation/bloc/history/history_bloc.dart';
import 'package:tata/features/adherence_analytics/presentation/bloc/history/history_event.dart';
import 'package:tata/features/adherence_analytics/presentation/bloc/history/history_state.dart';
import 'package:tata/features/adherence_analytics/presentation/screens/adherence_history_screen.dart';
import 'package:tata/features/adherence_analytics/presentation/widgets/adherence_trend_chart.dart';
import 'package:tata/l10n/generated/app_localizations.dart';
import 'package:tata/shared/common/result/app_result.dart';
import 'package:tata/shared/presentation/theme/tata_theme.dart';

import '../../support/visual_capture.dart';
import '../support/adherence_fixtures.dart';

/// Serves each requested calendar period rather than relabelling monthly values.
final class _Reader implements AdherenceReader {
  final requests = <int>[];
  @override
  Future<AppResult<AdherenceSummary?>> summary(
    String id,
    int days, {
    String? treatmentId,
  }) async {
    requests.add(days);
    final base = sampleSummary(periodDays: days);
    return AppSuccess(
      AdherenceSummary(
        periodDays: days,
        scheduledCount: days == 7 ? 24 : base.scheduledCount,
        adherencePercent: days == 7 ? 88 : base.adherencePercent,
        adherenceChangePercent: base.adherenceChangePercent,
        onTimePercent: days == 7 ? 71 : base.onTimePercent,
        onTimeChangePercent: base.onTimeChangePercent,
        lateCount: days == 7 ? 4 : base.lateCount,
        omittedCount: days == 7 ? 3 : base.omittedCount,
        trend: days == 7
            ? [
                for (var i = 0; i < 7; i++)
                  AdherenceTrendPoint(
                    date: DateTime(2026, 11, 4 + i),
                    adherencePercent: base.trend[i].adherencePercent,
                  ),
              ]
            : base.trend,
        recentIntakes: base.recentIntakes,
        pattern: days == 7
            ? const DetectedPattern(
                timeBand: AdherenceTimeBand.evening,
                omittedCount: 3,
                lateCount: 4,
              )
            : base.pattern,
      ),
    );
  }
}

void main() {
  setUpAll(loadTataFonts);
  for (final days in [30, 7]) {
    for (final scale in [1.0, 1.5, 1.95]) {
      testWidgets(
        'history $days days renders real period and dates at scale $scale',
        (tester) async {
          tester.view.physicalSize = scale == 1
              ? const Size(393, 883)
              : const Size(360, 640);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          final reader = _Reader();
          final bloc = HistoryBloc(
            olderAdultId: 'adult-A',
            summary: GetAdherenceSummary(reader),
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
                  key: const Key('history-variant-capture'),
                  child: child!,
                ),
              ),
              home: BlocProvider(
                create: (_) => bloc..add(const HistoryRequested()),
                child: BlocBuilder<HistoryBloc, HistoryState>(
                  builder: (context, state) => AdherenceHistoryScreen(
                    state: state,
                    clock: () => fixtureNow,
                    onPeriodSelected: (period) =>
                        bloc.add(HistoryPeriodSelected(period)),
                    onOpenRecommendations: () {},
                    onRetry: () => bloc.add(const HistoryRequested()),
                    onTabSelected: (_) {},
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          if (days == 7) {
            await tester.tap(find.byTooltip('Cambiar período').first);
            await tester.pumpAndSettle();
            await tester.tap(find.text('Últimos 7 días'));
            await tester.pumpAndSettle();
            expect(reader.requests, [30, 7]);
            expect(find.text('últ. 7 días'), findsOneWidget);
            expect(find.text('últ. 30 días'), findsNothing);
            expect(find.text('4 nov'), findsWidgets);
            expect(find.text('11 oct'), findsNothing);
          }
          expect(find.text('Últimos $days días ⌄'), findsOneWidget);
          expect(
            tester.getSize(find.text('92%\n10 nov')).height,
            lessThanOrEqualTo(2 * 11 * scale * 1.2 + 1),
            reason: 'The latest date must remain on its own complete line',
          );
          await captureWidget(
            tester,
            find.byKey(const Key('history-variant-capture')),
            'history-$days-$scale-top',
          );
          if (scale > 1) {
            await Scrollable.ensureVisible(
              tester.element(find.byType(AdherenceTrendCard)),
              alignment: 0.1,
            );
            await tester.pumpAndSettle();
            await captureWidget(
              tester,
              find.byKey(const Key('history-variant-capture')),
              'history-$days-$scale-chart',
            );
          }
          await tester.ensureVisible(find.text('Vitamina D3, omitida'));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
