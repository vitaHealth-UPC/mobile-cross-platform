import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../shared/common/result/app_result.dart';
import '../../../application/usecases/get_adherence_summary.dart';
import 'level_event.dart';
import 'level_state.dart';

/// Loads the adherence of the last [_periodDays] days of one adult for a host
/// screen that shows it as a card: the monthly level of the person profile or
/// the weekly card of the family summary.
///
/// Only the latest request may emit, so a slow earlier answer never replaces it.
final class LevelBloc extends Bloc<LevelEvent, LevelState> {
  LevelBloc({
    required this._olderAdultId,
    required this._summary,
    this._periodDays = adherenceLevelPeriodDays,
  }) : super(const LevelState()) {
    on<LevelRequested>(_load);
  }

  final String _olderAdultId;
  final GetAdherenceSummary _summary;
  final int _periodDays;
  int _revision = 0;

  Future<void> _load(LevelRequested event, Emitter<LevelState> emit) async {
    final revision = ++_revision;
    emit(const LevelState());
    final result = await _summary(_olderAdultId, _periodDays);
    if (revision != _revision || emit.isDone) return;
    switch (result) {
      case AppSuccess(:final value) when value != null:
        emit(LevelState(status: LevelStatus.content, summary: value));
      case AppSuccess():
        emit(const LevelState(status: LevelStatus.insufficientData));
      case AppFailure(:final code):
        emit(LevelState(status: LevelStatus.failure, errorCode: code));
    }
  }
}
