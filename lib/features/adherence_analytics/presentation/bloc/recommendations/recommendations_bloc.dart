import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../shared/common/result/app_result.dart';
import '../../../application/usecases/get_recommendations.dart';
import 'recommendations_event.dart';
import 'recommendations_state.dart';

/// Presents the recommendations of the latest requested load.
///
/// The bloc never derives a recommendation: an absent server insight is shown
/// as insufficient evidence.
final class RecommendationsBloc
    extends Bloc<RecommendationsEvent, RecommendationsState> {
  RecommendationsBloc({
    required this._olderAdultId,
    required this._recommendations,
  }) : super(const RecommendationsState()) {
    on<RecommendationsRequested>(_load);
  }

  final String _olderAdultId;
  final GetRecommendations _recommendations;
  int _revision = 0;

  Future<void> _load(
    RecommendationsRequested event,
    Emitter<RecommendationsState> emit,
  ) async {
    final revision = ++_revision;
    emit(const RecommendationsState());
    final result = await _recommendations(
      _olderAdultId,
      recommendationsPeriodDays,
    );
    if (revision != _revision || emit.isDone) return;
    switch (result) {
      case AppSuccess(:final value) when value != null:
        emit(
          RecommendationsState(
            status: RecommendationsStatus.content,
            insight: value,
          ),
        );
      case AppSuccess():
        emit(
          const RecommendationsState(
            status: RecommendationsStatus.insufficientEvidence,
          ),
        );
      case AppFailure(:final code):
        emit(
          RecommendationsState(
            status: RecommendationsStatus.failure,
            errorCode: code,
          ),
        );
    }
  }
}
