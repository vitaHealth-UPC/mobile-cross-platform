import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../shared/common/result/app_result.dart';
import '../../../application/readmodels/treatment_detail.dart';
import '../../../application/usecases/list_medications.dart';
import '../../../application/usecases/list_treatments.dart';
import '../../../domain/entities/medication.dart';
import 'treatment_list_event.dart';
import 'treatment_list_state.dart';

/// Loads the treatment catalog of one adult; only the latest request may emit.
final class TreatmentListBloc
    extends Bloc<TreatmentListEvent, TreatmentListState> {
  TreatmentListBloc({
    required this._list,
    required this.olderAdultId,
    this._medications,
  }) : super(const TreatmentListState()) {
    on<TreatmentListRequested>(_load);
  }

  final ListTreatments _list;

  /// Optional catalog used only to label each regimen with its medication.
  final ListMedications? _medications;
  final String olderAdultId;
  int _revision = 0;

  Future<void> _load(
    TreatmentListRequested event,
    Emitter<TreatmentListState> emit,
  ) async {
    final revision = ++_revision;
    final previous = state.treatments;
    emit(TreatmentListState(treatments: previous));
    final (result, catalog) = await (
      _list(olderAdultId),
      _medications?.call(olderAdultId) ??
          Future.value(const AppSuccess(<Medication>[])),
    ).wait;
    if (revision != _revision || emit.isDone) return;
    emit(switch (result) {
      AppSuccess<List<TreatmentDetail>>(:final value) => TreatmentListState(
        status: TreatmentListStatus.ready,
        treatments: value,
        activated: event.activated,
        medicationLabels: switch (catalog) {
          AppSuccess(:final value) => {
            for (final medication in value) medication.id: medication.label,
          },
          AppFailure() => state.medicationLabels,
        },
      ),
      AppFailure<List<TreatmentDetail>>(:final code) => TreatmentListState(
        status: TreatmentListStatus.failure,
        treatments: previous,
        errorCode: code,
      ),
    });
  }
}
