import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tata/features/adherence_analytics/application/ports/recommendations_reader.dart';
import 'package:tata/features/adherence_analytics/application/readmodels/adherence_recommendation.dart';
import 'package:tata/features/adherence_analytics/application/readmodels/adherence_summary.dart';
import 'package:tata/features/adherence_analytics/application/usecases/get_recommendations.dart';
import 'package:tata/features/adherence_analytics/presentation/bloc/recommendations/recommendations_bloc.dart';
import 'package:tata/features/adherence_analytics/presentation/bloc/recommendations/recommendations_event.dart';
import 'package:tata/features/adherence_analytics/presentation/bloc/recommendations/recommendations_state.dart';
import 'package:tata/shared/common/result/app_result.dart';

/// Test double: the handler decides the answer of each call.
final class _Reader implements RecommendationsReader {
  _Reader(this.handler);

  final Future<AppResult<AdherenceInsight?>> Function() handler;
  final requests = <(String, int)>[];

  @override
  Future<AppResult<AdherenceInsight?>> insight(
    String olderAdultId,
    int periodDays,
  ) {
    requests.add((olderAdultId, periodDays));
    return handler();
  }
}

AdherenceInsight _insight({int omitted = 4}) => AdherenceInsight(
  periodDays: 30,
  pattern: AdherenceInsightPattern(
    type: AdherencePatternType.omission,
    timeBand: AdherenceTimeBand.evening,
    omittedCount: omitted,
    lateCount: 2,
    fromHour: 18,
    toHour: 21,
  ),
  concentration: List.generate(3, (_) => List.filled(7, 0.2)),
  recommendations: const [AdherenceRecommendation.adjustReminder],
);

Matcher _state(
  RecommendationsStatus status, {
  String? errorCode,
  int? omitted,
}) => isA<RecommendationsState>()
    .having((s) => s.status, 'status', status)
    .having((s) => s.errorCode, 'errorCode', errorCode)
    .having((s) => s.insight?.pattern.omittedCount, 'omitted', omitted);

RecommendationsBloc _bloc(_Reader reader) => RecommendationsBloc(
  olderAdultId: 'adult-A',
  recommendations: GetRecommendations(reader),
);

void main() {
  blocTest<RecommendationsBloc, RecommendationsState>(
    'asks for thirty days and shows the server insight',
    build: () => _bloc(_Reader(() async => AppSuccess(_insight()))),
    act: (bloc) => bloc.add(const RecommendationsRequested()),
    expect: () => [
      _state(RecommendationsStatus.loading),
      _state(RecommendationsStatus.content, omitted: 4),
    ],
  );

  test('the request carries the adult and the fixed period', () async {
    final reader = _Reader(() async => AppSuccess(_insight()));
    final bloc = _bloc(reader)..add(const RecommendationsRequested());
    await bloc.stream.firstWhere(
      (s) => s.status == RecommendationsStatus.content,
    );

    expect(reader.requests, [('adult-A', recommendationsPeriodDays)]);
    await bloc.close();
  });

  blocTest<RecommendationsBloc, RecommendationsState>(
    'no server insight is insufficient evidence, never a local conclusion',
    build: () => _bloc(_Reader(() async => const AppSuccess(null))),
    act: (bloc) => bloc.add(const RecommendationsRequested()),
    expect: () => [
      _state(RecommendationsStatus.loading),
      _state(RecommendationsStatus.insufficientEvidence),
    ],
  );

  blocTest<RecommendationsBloc, RecommendationsState>(
    'a failure keeps its code and a retry loads the insight',
    build: () {
      var calls = 0;
      return _bloc(
        _Reader(
          () async => ++calls == 1
              ? const AppFailure('ACCESS_DENIED')
              : AppSuccess(_insight()),
        ),
      );
    },
    act: (bloc) async {
      bloc.add(const RecommendationsRequested());
      await Future<void>.delayed(Duration.zero);
      bloc.add(const RecommendationsRequested());
    },
    expect: () => [
      _state(RecommendationsStatus.loading),
      _state(RecommendationsStatus.failure, errorCode: 'ACCESS_DENIED'),
      _state(RecommendationsStatus.loading),
      _state(RecommendationsStatus.content, omitted: 4),
    ],
  );

  test('a slow earlier answer never replaces the latest request', () async {
    final slow = Completer<AppResult<AdherenceInsight?>>();
    var calls = 0;
    final bloc = _bloc(
      _Reader(
        () => ++calls == 1
            ? slow.future
            : Future.value(AppSuccess(_insight(omitted: 7))),
      ),
    )..add(const RecommendationsRequested());
    await Future<void>.delayed(Duration.zero);

    bloc.add(const RecommendationsRequested());
    await bloc.stream.firstWhere(
      (s) => s.status == RecommendationsStatus.content,
    );
    slow.complete(AppSuccess(_insight(omitted: 1)));
    await Future<void>.delayed(Duration.zero);

    expect(bloc.state.insight?.pattern.omittedCount, 7);
    await bloc.close();
  });
}
