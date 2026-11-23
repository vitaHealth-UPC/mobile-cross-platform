import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../shared/common/result/app_result.dart';
import '../../../application/usecases/get_adherence_summary.dart';
import 'history_event.dart';
import 'history_state.dart';

/// Owns the selected period of one adult's adherence history.
///
/// Only the latest request may emit, so a slow answer for a previous period
/// never replaces the one on screen.
final class HistoryBloc extends Bloc<HistoryEvent, HistoryState> {
  HistoryBloc({required this._olderAdultId, required this._summary})
    : super(const HistoryState()) {
    on<HistoryRequested>((event, emit) => _load(emit, state));
    on<HistoryPeriodSelected>(_select);
  }

  final String _olderAdultId;
  final GetAdherenceSummary _summary;
  int _revision = 0;
  bool _periodChanged = false;

  Future<void> _select(
    HistoryPeriodSelected event,
    Emitter<HistoryState> emit,
  ) {
    if (event.period == state.period) return Future.value();
    _periodChanged = true;
    return _load(emit, state.copyWith(period: event.period));
  }

  Future<void> _load(Emitter<HistoryState> emit, HistoryState target) async {
    final revision = ++_revision;
    final period = target.period;
    emit(target.copyWith(status: HistoryStatus.loading));
    final result = await _summary(_olderAdultId, period.days);
    if (revision != _revision || emit.isDone) return;
    switch (result) {
      case AppSuccess(:final value) when value != null:
        emit(
          state.copyWith(
            status: HistoryStatus.content,
            summary: value,
            periodUpdated: _periodChanged,
          ),
        );
      case AppSuccess():
        emit(
          state.copyWith(
            status: _periodChanged
                ? HistoryStatus.noResults
                : HistoryStatus.insufficientData,
          ),
        );
      case AppFailure(:final code):
        emit(state.copyWith(status: HistoryStatus.failure, errorCode: code));
    }
  }
}
