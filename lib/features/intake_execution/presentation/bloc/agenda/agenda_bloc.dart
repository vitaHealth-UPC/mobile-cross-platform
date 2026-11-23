import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../shared/application/time/clock.dart';
import '../../../../../shared/common/result/app_result.dart';
import '../../../application/readmodels/agenda_week.dart';
import '../../../application/usecases/get_week_agenda.dart';
import 'agenda_event.dart';
import 'agenda_state.dart';

/// Owns the selected week and day; only the latest week request may emit, so a
/// slow response for a previous week never replaces the visible one.
final class AgendaBloc extends Bloc<AgendaEvent, AgendaState> {
  AgendaBloc({required this._agenda, required Clock clock})
    : super(_initial(clock())) {
    on<AgendaRequested>((event, emit) => _load(emit, state));
    on<AgendaDaySelected>(_select);
    on<AgendaWeekMoved>(
      (event, emit) => _load(
        emit,
        state.copyWith(
          week: state.week.shift(event.weeks),
          selectedDay: DateTime(
            state.selectedDay.year,
            state.selectedDay.month,
            state.selectedDay.day + 7 * event.weeks,
          ),
          intakes: const [],
        ),
      ),
    );
  }

  final GetWeekAgenda _agenda;
  int _revision = 0;

  static AgendaState _initial(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    return AgendaState(week: AgendaWeek.containing(today), selectedDay: today);
  }

  void _select(AgendaDaySelected event, Emitter<AgendaState> emit) {
    final day = DateTime(event.day.year, event.day.month, event.day.day);
    if (state.week.contains(day)) emit(state.copyWith(selectedDay: day));
  }

  Future<void> _load(Emitter<AgendaState> emit, AgendaState target) async {
    final revision = ++_revision;
    emit(target.copyWith(status: AgendaStatus.loading));
    final result = await _agenda(target.week);
    if (revision != _revision || emit.isDone) return;
    switch (result) {
      case AppSuccess(:final value):
        emit(state.copyWith(status: AgendaStatus.ready, intakes: value));
      case AppFailure(:final code):
        emit(
          state.copyWith(
            status: AgendaStatus.failure,
            intakes: const [],
            errorCode: code,
          ),
        );
    }
  }
}
