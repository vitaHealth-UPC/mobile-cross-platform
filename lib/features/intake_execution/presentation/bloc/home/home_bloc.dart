import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../shared/common/result/app_result.dart';
import '../../../application/readmodels/daily_progress.dart';
import '../../../application/usecases/get_daily_progress.dart';
import '../../../application/usecases/get_next_intake.dart';
import '../../../domain/entities/intake.dart';
import 'home_event.dart';
import 'home_state.dart';

/// Loads the next intake and today's progress together; only the latest request
/// may emit, so a slow earlier refresh never overwrites a newer result.
final class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc({required this._next, required this._progress})
    : super(const HomeState()) {
    on<HomeRequested>(_load);
  }

  final GetNextIntake _next;
  final GetDailyProgress _progress;
  int _revision = 0;

  Future<void> _load(HomeRequested event, Emitter<HomeState> emit) async {
    final revision = ++_revision;
    emit(const HomeState());
    // Both reads start before either is awaited.
    final pendingNext = _next();
    final pendingProgress = _progress();
    final next = await pendingNext;
    final progress = await pendingProgress;
    if (revision != _revision || emit.isDone) return;
    if (progress case AppFailure(:final code)
        when const {
          'AUTHENTICATION_REQUIRED',
          'SESSION_CHANGED',
          'ACCESS_DENIED',
        }.contains(code)) {
      emit(HomeState(status: HomeStatus.failure, errorCode: code));
      return;
    }
    switch (next) {
      case AppFailure<Intake?>(:final code):
        emit(HomeState(status: HomeStatus.failure, errorCode: code));
      case AppSuccess<Intake?>(:final value):
        emit(
          HomeState(
            status: HomeStatus.ready,
            next: value,
            progress: progress is AppSuccess<DailyProgress>
                ? progress.value
                : null,
          ),
        );
    }
  }
}
