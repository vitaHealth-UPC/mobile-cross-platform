import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../shared/common/result/app_result.dart';
import '../../../application/readmodels/treatment_readmodels.dart';
import '../../../application/usecases/treatment_usecases.dart';
import 'treatment_list_event.dart';
import 'treatment_list_state.dart';

/// Loads the treatment catalog of one adult; only the latest request may emit.
final class TreatmentListBloc
    extends Bloc<TreatmentListEvent, TreatmentListState> {
  TreatmentListBloc({required this._list, required this.olderAdultId})
    : super(const TreatmentListState()) {
    on<TreatmentListRequested>(_load);
  }

  final ListTreatments _list;
  final String olderAdultId;
  int _revision = 0;

  Future<void> _load(
    TreatmentListRequested event,
    Emitter<TreatmentListState> emit,
  ) async {
    final revision = ++_revision;
    final previous = state.treatments;
    emit(TreatmentListState(treatments: previous));
    final result = await _list(olderAdultId);
    if (revision != _revision || emit.isDone) return;
    emit(switch (result) {
      AppSuccess<List<TreatmentDetail>>(:final value) => TreatmentListState(
        status: TreatmentListStatus.ready,
        treatments: value,
      ),
      AppFailure<List<TreatmentDetail>>(:final code) => TreatmentListState(
        status: TreatmentListStatus.failure,
        treatments: previous,
        errorCode: code,
      ),
    });
  }
}
