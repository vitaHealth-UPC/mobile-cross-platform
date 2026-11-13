import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tata/features/adherence_analytics/application/ports/adherence_reader.dart';
import 'package:tata/features/adherence_analytics/application/readmodels/adherence_period.dart';
import 'package:tata/features/adherence_analytics/application/readmodels/adherence_summary.dart';
import 'package:tata/features/adherence_analytics/application/usecases/get_adherence_summary.dart';
import 'package:tata/features/adherence_analytics/presentation/bloc/history/history_bloc.dart';
import 'package:tata/features/adherence_analytics/presentation/bloc/history/history_event.dart';
import 'package:tata/features/adherence_analytics/presentation/bloc/history/history_state.dart';
import 'package:tata/shared/common/result/app_result.dart';

/// Test double: the handler decides the answer for each requested period.
final class _Reader implements AdherenceReader {
  _Reader(this.handler);

  final Future<AppResult<AdherenceSummary?>> Function(int days) handler;
  final requests = <(String, int)>[];

  @override
  Future<AppResult<AdherenceSummary?>> summary(
    String olderAdultId,
    int periodDays, {
    String? treatmentId,
  }) {
    requests.add((olderAdultId, periodDays));
    return handler(periodDays);
  }
}

AdherenceSummary _summary(int days, {int percent = 92}) => AdherenceSummary(
  periodDays: days,
  scheduledCount: 20,
  adherencePercent: percent,
  onTimePercent: 80,
  lateCount: 2,
  omittedCount: 1,
  trend: const [],
  recentIntakes: const [],
);

Matcher _state(
  HistoryStatus status, {
  AdherencePeriod period = AdherencePeriod.lastMonth,
  bool periodUpdated = false,
  String? errorCode,
  int? percent,
}) => isA<HistoryState>()
    .having((s) => s.status, 'status', status)
    .having((s) => s.period, 'period', period)
    .having((s) => s.periodUpdated, 'periodUpdated', periodUpdated)
    .having((s) => s.errorCode, 'errorCode', errorCode)
    .having((s) => s.summary?.adherencePercent, 'percent', percent);

HistoryBloc _bloc(_Reader reader) =>
    HistoryBloc(olderAdultId: 'adult-A', summary: GetAdherenceSummary(reader));

void main() {
  blocTest<HistoryBloc, HistoryState>(
    'loads the last thirty days first',
    build: () => _bloc(_Reader((days) async => AppSuccess(_summary(days)))),
    act: (bloc) => bloc.add(const HistoryRequested()),
    expect: () => [
      _state(HistoryStatus.loading),
      _state(HistoryStatus.content, percent: 92),
    ],
    verify: (bloc) {
      expect(bloc.state.summary?.periodDays, 30);
    },
  );

  blocTest<HistoryBloc, HistoryState>(
    'a first load without definitive intakes is insufficient data',
    build: () => _bloc(_Reader((_) async => const AppSuccess(null))),
    act: (bloc) => bloc.add(const HistoryRequested()),
    expect: () => [
      _state(HistoryStatus.loading),
      _state(HistoryStatus.insufficientData),
    ],
  );

  blocTest<HistoryBloc, HistoryState>(
    'selecting a period reloads it and marks the content as updated',
    build: () => _bloc(_Reader((days) async => AppSuccess(_summary(days)))),
    act: (bloc) async {
      bloc.add(const HistoryRequested());
      await Future<void>.delayed(Duration.zero);
      bloc.add(const HistoryPeriodSelected(AdherencePeriod.lastWeek));
    },
    expect: () => [
      _state(HistoryStatus.loading),
      _state(HistoryStatus.content, percent: 92),
      _state(HistoryStatus.loading, period: AdherencePeriod.lastWeek),
      _state(
        HistoryStatus.content,
        period: AdherencePeriod.lastWeek,
        periodUpdated: true,
        percent: 92,
      ),
    ],
  );

  blocTest<HistoryBloc, HistoryState>(
    'a selected period without intakes reads as no results',
    build: () => _bloc(
      _Reader(
        (days) async =>
            days == 7 ? const AppSuccess(null) : AppSuccess(_summary(days)),
      ),
    ),
    act: (bloc) async {
      bloc.add(const HistoryRequested());
      await Future<void>.delayed(Duration.zero);
      bloc.add(const HistoryPeriodSelected(AdherencePeriod.lastWeek));
    },
    skip: 2,
    expect: () => [
      _state(HistoryStatus.loading, period: AdherencePeriod.lastWeek),
      _state(HistoryStatus.noResults, period: AdherencePeriod.lastWeek),
    ],
  );

  test('selecting the current period does not read again', () async {
    final reader = _Reader((days) async => AppSuccess(_summary(days)));
    final bloc = _bloc(reader)..add(const HistoryRequested());
    await bloc.stream.firstWhere((s) => s.status == HistoryStatus.content);

    bloc.add(const HistoryPeriodSelected(AdherencePeriod.lastMonth));
    await Future<void>.delayed(Duration.zero);

    expect(reader.requests, [('adult-A', 30)]);
    await bloc.close();
  });

  blocTest<HistoryBloc, HistoryState>(
    'a failure keeps its code and a retry loads the content',
    build: () {
      var calls = 0;
      return _bloc(
        _Reader(
          (days) async => ++calls == 1
              ? const AppFailure('NETWORK_UNAVAILABLE')
              : AppSuccess(_summary(days)),
        ),
      );
    },
    act: (bloc) async {
      bloc.add(const HistoryRequested());
      await Future<void>.delayed(Duration.zero);
      bloc.add(const HistoryRequested());
    },
    expect: () => [
      _state(HistoryStatus.loading),
      _state(HistoryStatus.failure, errorCode: 'NETWORK_UNAVAILABLE'),
      _state(HistoryStatus.loading),
      _state(HistoryStatus.content, percent: 92),
    ],
  );

  test(
    'a slow answer for a previous period never replaces the latest',
    () async {
      final slow = Completer<AppResult<AdherenceSummary?>>();
      final reader = _Reader(
        (days) => days == 30
            ? slow.future
            : Future.value(AppSuccess(_summary(days, percent: 55))),
      );
      final bloc = _bloc(reader)..add(const HistoryRequested());
      await Future<void>.delayed(Duration.zero);

      bloc.add(const HistoryPeriodSelected(AdherencePeriod.lastWeek));
      await bloc.stream.firstWhere((s) => s.status == HistoryStatus.content);
      slow.complete(AppSuccess(_summary(30, percent: 99)));
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.period, AdherencePeriod.lastWeek);
      expect(bloc.state.summary?.adherencePercent, 55);
      await bloc.close();
    },
  );

  blocTest<HistoryBloc, HistoryState>(
    'an invalid adult is reported without any request',
    build: () {
      final reader = _Reader((days) async => AppSuccess(_summary(days)));
      return HistoryBloc(
        olderAdultId: ' ',
        summary: GetAdherenceSummary(reader),
      );
    },
    act: (bloc) => bloc.add(const HistoryRequested()),
    expect: () => [
      _state(HistoryStatus.loading),
      _state(HistoryStatus.failure, errorCode: 'INVALID_OLDER_ADULT_REFERENCE'),
    ],
  );
}
