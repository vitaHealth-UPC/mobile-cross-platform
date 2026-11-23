import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tata/features/adherence_analytics/application/ports/adherence_reader.dart';
import 'package:tata/features/adherence_analytics/application/readmodels/adherence_summary.dart';
import 'package:tata/features/adherence_analytics/application/usecases/get_adherence_summary.dart';
import 'package:tata/features/adherence_analytics/presentation/bloc/level/level_bloc.dart';
import 'package:tata/features/adherence_analytics/presentation/bloc/level/level_state.dart';
import 'package:tata/features/adherence_analytics/presentation/navigation/weekly_adherence_view.dart';
import 'package:tata/features/adherence_analytics/presentation/widgets/weekly_adherence_card.dart';
import 'package:tata/shared/common/result/app_result.dart';

import '../../support/visual_capture.dart';
import '../support/adherence_fixtures.dart';

/// Test double: the handler decides the answer; every request is recorded.
final class _Reader implements AdherenceReader {
  _Reader(this.handler);

  final Future<AppResult<AdherenceSummary?>> Function() handler;
  final requests = <(String, int)>[];

  @override
  Future<AppResult<AdherenceSummary?>> summary(
    String olderAdultId,
    int periodDays,
  ) {
    requests.add((olderAdultId, periodDays));
    return handler();
  }
}

LevelBloc _weekBloc(_Reader reader) => LevelBloc(
  olderAdultId: 'adult-A',
  summary: GetAdherenceSummary(reader),
  periodDays: adherenceWeekPeriodDays,
);

void main() {
  setUpAll(loadTataFonts);

  group('adherenceGaugeLitSegments', () {
    test('lights one segment for every started fifth', () {
      expect(adherenceGaugeLitSegments(0), 0);
      expect(adherenceGaugeLitSegments(1), 1);
      expect(adherenceGaugeLitSegments(20), 1);
      expect(adherenceGaugeLitSegments(21), 2);
      expect(adherenceGaugeLitSegments(50), 3);
      expect(adherenceGaugeLitSegments(92), 5);
      expect(adherenceGaugeLitSegments(100), 5);
    });
  });

  group('WeeklyAdherenceCard', () {
    Future<void> pumpCard(
      WidgetTester tester, {
      int percent = 92,
      String name = 'Rosa',
      Locale locale = const Locale('es'),
    }) async {
      useFigmaPhone(tester);
      await tester.pumpWidget(
        RepaintBoundary(
          key: const Key('weekly-capture'),
          child: adherenceApp(
            Scaffold(
              body: Padding(
                padding: const EdgeInsets.all(22),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: WeeklyAdherenceCard(
                    adherencePercent: percent,
                    personName: name,
                  ),
                ),
              ),
            ),
            locale: locale,
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('draws the Figma weekly card for a good week', (tester) async {
      await pumpCard(tester);
      await captureWidget(
        tester,
        find.byKey(const Key('weekly-capture')),
        'adherence-weekly-card',
      );

      expect(find.text('Adherencia esta semana'), findsOneWidget);
      expect(find.text('92%'), findsOneWidget);
      expect(find.text('Muy bien, Rosa'), findsOneWidget);
      // Figma frame: 349 x 118.
      final size = tester.getSize(find.byType(WeeklyAdherenceCard));
      expect(size.width, closeTo(349, 1));
      expect(size.height, closeTo(118, 2));
    });

    testWidgets('the text keeps the Figma positions', (tester) async {
      await pumpCard(tester);

      final card = tester.getTopLeft(find.byType(WeeklyAdherenceCard));
      final title = tester.getTopLeft(find.text('Adherencia esta semana'));
      final figure = tester.getTopLeft(find.text('92%'));
      final message = tester.getTopLeft(find.text('Muy bien, Rosa'));
      // Figma: title at 16, figure at 42 and message at 78 from the top.
      expect(title.dx - card.dx, closeTo(16, 0.5));
      expect(title.dy - card.dy, closeTo(16, 1.5));
      expect(figure.dy - card.dy, closeTo(42, 2));
      expect(message.dy - card.dy, closeTo(78, 3));
    });

    testWidgets('below ninety percent it supports instead of praising', (
      tester,
    ) async {
      await pumpCard(tester, percent: 70);

      expect(find.text('Sigamos acompañando a Rosa'), findsOneWidget);
      expect(find.textContaining('Muy bien'), findsNothing);
    });

    testWidgets('speaks English', (tester) async {
      await pumpCard(tester, locale: const Locale('en'));

      expect(find.text('Adherence this week'), findsOneWidget);
      expect(find.text('Well done, Rosa'), findsOneWidget);
    });

    testWidgets('has one screen reader summary', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpCard(tester);

      expect(
        find.bySemanticsLabel(
          'Adherencia esta semana de Rosa: 92%. Muy bien, Rosa',
        ),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('a long name never overflows next to the gauge', (
      tester,
    ) async {
      await pumpCard(tester, name: 'María de los Ángeles Fernández');

      expect(tester.takeException(), isNull);
    });

    testWidgets('survives 150 percent text and a list without a height', (
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
            const Scaffold(
              body: SingleChildScrollView(
                padding: EdgeInsets.all(22),
                child: WeeklyAdherenceCard(
                  adherencePercent: 92,
                  personName: 'Rosa',
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });

  group('WeeklyAdherenceView', () {
    Future<void> pumpView(
      WidgetTester tester,
      _Reader reader, {
      VoidCallback? onInvalidated,
    }) async {
      useFigmaPhone(tester);
      await tester.pumpWidget(
        adherenceApp(
          Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(22),
              child: WeeklyAdherenceView(
                createBloc: () => _weekBloc(reader),
                personName: 'Rosa',
                onSessionInvalidated: onInvalidated ?? () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('asks for seven days and shows the week of the adult', (
      tester,
    ) async {
      final reader = _Reader(() async => AppSuccess(sampleSummary()));
      await pumpView(tester, reader);

      expect(find.text('Muy bien, Rosa'), findsOneWidget);
      expect(reader.requests, [('adult-A', 7)]);
    });

    testWidgets('says so in the same frame when there is no evidence', (
      tester,
    ) async {
      await pumpView(tester, _Reader(() async => const AppSuccess(null)));

      expect(find.text('Adherencia esta semana'), findsOneWidget);
      expect(find.text('Sin datos suficientes'), findsOneWidget);
    });

    testWidgets('a failure offers a retry that loads the week', (tester) async {
      var calls = 0;
      await pumpView(
        tester,
        _Reader(
          () async => ++calls == 1
              ? const AppFailure('NETWORK_UNAVAILABLE')
              : AppSuccess(sampleSummary()),
        ),
      );
      expect(
        find.text('No hay conexión. Inténtalo nuevamente.'),
        findsOneWidget,
      );

      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();

      expect(find.text('Muy bien, Rosa'), findsOneWidget);
    });

    testWidgets('a rejected credential reaches the host, not the card', (
      tester,
    ) async {
      var invalidated = 0;
      await pumpView(
        tester,
        _Reader(() async => const AppFailure('SESSION_CHANGED')),
        onInvalidated: () => invalidated++,
      );

      expect(invalidated, 1);
    });
  });
}
