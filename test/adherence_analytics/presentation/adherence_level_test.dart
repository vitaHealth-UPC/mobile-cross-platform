import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tata/features/adherence_analytics/application/ports/adherence_reader.dart';
import 'package:tata/features/adherence_analytics/application/readmodels/adherence_summary.dart';
import 'package:tata/features/adherence_analytics/application/usecases/get_adherence_summary.dart';
import 'package:tata/features/adherence_analytics/presentation/bloc/level/level_bloc.dart';
import 'package:tata/features/adherence_analytics/presentation/bloc/level/level_event.dart';
import 'package:tata/features/adherence_analytics/presentation/bloc/level/level_state.dart';
import 'package:tata/features/adherence_analytics/presentation/navigation/adherence_level_view.dart';
import 'package:tata/features/adherence_analytics/presentation/widgets/adherence_level_card.dart';
import 'package:tata/shared/common/result/app_result.dart';

import '../../support/visual_capture.dart';
import '../support/adherence_fixtures.dart';

/// Test double: the handler decides the answer for each requested period.
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

LevelBloc _bloc(_Reader reader) =>
    LevelBloc(olderAdultId: 'adult-A', summary: GetAdherenceSummary(reader));

Matcher _state(LevelStatus status, {String? errorCode, int? percent}) =>
    isA<LevelState>()
        .having((s) => s.status, 'status', status)
        .having((s) => s.errorCode, 'errorCode', errorCode)
        .having((s) => s.summary?.adherencePercent, 'percent', percent);

void main() {
  setUpAll(loadTataFonts);

  group('LevelBloc', () {
    blocTest<LevelBloc, LevelState>(
      'asks for the last thirty days and shows the level',
      build: () => _bloc(_Reader(() async => AppSuccess(sampleSummary()))),
      act: (bloc) => bloc.add(const LevelRequested()),
      expect: () => [
        _state(LevelStatus.loading),
        _state(LevelStatus.content, percent: 92),
      ],
    );

    test('the request carries the adult and the thirty day period', () async {
      final reader = _Reader(() async => AppSuccess(sampleSummary()));
      final bloc = _bloc(reader)..add(const LevelRequested());
      await bloc.stream.firstWhere((s) => s.status == LevelStatus.content);

      expect(reader.requests, [('adult-A', adherenceLevelPeriodDays)]);
      await bloc.close();
    });

    blocTest<LevelBloc, LevelState>(
      'no definitive intakes is insufficient data',
      build: () => _bloc(_Reader(() async => const AppSuccess(null))),
      act: (bloc) => bloc.add(const LevelRequested()),
      expect: () => [
        _state(LevelStatus.loading),
        _state(LevelStatus.insufficientData),
      ],
    );

    blocTest<LevelBloc, LevelState>(
      'a failure keeps its code and a retry loads the level',
      build: () {
        var calls = 0;
        return _bloc(
          _Reader(
            () async => ++calls == 1
                ? const AppFailure('NETWORK_UNAVAILABLE')
                : AppSuccess(sampleSummary()),
          ),
        );
      },
      act: (bloc) async {
        bloc.add(const LevelRequested());
        await Future<void>.delayed(Duration.zero);
        bloc.add(const LevelRequested());
      },
      expect: () => [
        _state(LevelStatus.loading),
        _state(LevelStatus.failure, errorCode: 'NETWORK_UNAVAILABLE'),
        _state(LevelStatus.loading),
        _state(LevelStatus.content, percent: 92),
      ],
    );

    test('a slow earlier answer never replaces the latest request', () async {
      final slow = Completer<AppResult<AdherenceSummary?>>();
      var calls = 0;
      final bloc = _bloc(
        _Reader(
          () => ++calls == 1
              ? slow.future
              : Future.value(AppSuccess(sampleSummary(adherencePercent: 55))),
        ),
      )..add(const LevelRequested());
      await Future<void>.delayed(Duration.zero);

      bloc.add(const LevelRequested());
      await bloc.stream.firstWhere((s) => s.status == LevelStatus.content);
      slow.complete(AppSuccess(sampleSummary(adherencePercent: 99)));
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.summary?.adherencePercent, 55);
      await bloc.close();
    });
  });

  group('AdherenceLevelCard', () {
    Future<void> pumpCard(
      WidgetTester tester, {
      int percent = 92,
      int? change = 8,
      int days = 30,
      Locale locale = const Locale('es'),
    }) async {
      useFigmaPhone(tester);
      await tester.pumpWidget(
        RepaintBoundary(
          key: const Key('level-capture'),
          child: adherenceApp(
            Scaffold(
              body: Padding(
                padding: const EdgeInsets.all(22),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: AdherenceLevelCard(
                    adherencePercent: percent,
                    changePercent: change,
                    periodDays: days,
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

    testWidgets('draws the Figma level card for an excellent month', (
      tester,
    ) async {
      await pumpCard(tester);
      await captureWidget(
        tester,
        find.byKey(const Key('level-capture')),
        'adherence-level-card',
      );

      expect(find.text('Nivel de adherencia'), findsOneWidget);
      expect(find.text('92%'), findsOneWidget);
      expect(find.text('Excelente'), findsOneWidget);
      expect(find.text('↑ 8% vs. mes anterior'), findsOneWidget);
      // Figma frame: 349 wide and about 100 tall, never the height of its host.
      final size = tester.getSize(find.byType(AdherenceLevelCard));
      expect(size.width, closeTo(349, 1));
      expect(size.height, inInclusiveRange(100, 110));
    });

    testWidgets('fits inside a scrolling list without bounded height', (
      tester,
    ) async {
      useFigmaPhone(tester);
      await tester.pumpWidget(
        adherenceApp(
          const Scaffold(
            body: SingleChildScrollView(
              padding: EdgeInsets.all(22),
              child: AdherenceLevelCard(
                adherencePercent: 92,
                changePercent: 8,
                periodDays: 30,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('names the comparison by week, month or number of days', (
      tester,
    ) async {
      await pumpCard(tester, days: 7);
      expect(find.text('↑ 8% vs. semana anterior'), findsOneWidget);

      await pumpCard(tester, days: 14, change: -3);
      expect(find.text('↓ 3% vs. 14 días previos'), findsOneWidget);
    });

    testWidgets('omits the comparison when the previous period had none', (
      tester,
    ) async {
      await pumpCard(tester, change: null);

      expect(find.textContaining('vs.'), findsNothing);
      expect(find.text('Excelente'), findsOneWidget);
    });

    testWidgets('below ninety percent it is under follow-up, not praise', (
      tester,
    ) async {
      await pumpCard(tester, percent: 89);

      expect(find.text('En seguimiento'), findsOneWidget);
      expect(find.text('Excelente'), findsNothing);
    });

    testWidgets('speaks English', (tester) async {
      await pumpCard(tester, locale: const Locale('en'));

      expect(find.text('Adherence level'), findsOneWidget);
      expect(find.text('Excellent'), findsOneWidget);
      expect(find.text('↑ 8% vs. previous month'), findsOneWidget);
    });

    testWidgets('has one screen reader summary', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpCard(tester);

      expect(
        find.bySemanticsLabel('Nivel de adherencia: Excelente, 92%.'),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('survives 150 percent text', (tester) async {
      useFigmaPhone(tester);
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(393, 883),
            textScaler: TextScaler.linear(1.5),
          ),
          child: adherenceApp(
            const Scaffold(
              body: Padding(
                padding: EdgeInsets.all(22),
                child: AdherenceLevelCard(
                  adherencePercent: 92,
                  changePercent: 8,
                  periodDays: 30,
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

  group('AdherenceLevelView', () {
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
              child: AdherenceLevelView(
                createBloc: () => _bloc(reader),
                onSessionInvalidated: onInvalidated ?? () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('loads and shows the level of the adult', (tester) async {
      final reader = _Reader(() async => AppSuccess(sampleSummary()));
      await pumpView(tester, reader);

      expect(find.text('Excelente'), findsOneWidget);
      expect(reader.requests, [('adult-A', 30)]);
    });

    testWidgets('says so in the same frame when there is no evidence', (
      tester,
    ) async {
      await pumpView(tester, _Reader(() async => const AppSuccess(null)));

      expect(find.text('Nivel de adherencia'), findsOneWidget);
      expect(find.text('Sin datos suficientes'), findsOneWidget);
    });

    testWidgets('a failure offers a retry that loads the level', (
      tester,
    ) async {
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

      expect(find.text('Excelente'), findsOneWidget);
    });

    testWidgets('a rejected credential reaches the host, not the card', (
      tester,
    ) async {
      var invalidated = 0;
      await pumpView(
        tester,
        _Reader(() async => const AppFailure('AUTHENTICATION_REQUIRED')),
        onInvalidated: () => invalidated++,
      );

      expect(invalidated, 1);
    });
  });
}
