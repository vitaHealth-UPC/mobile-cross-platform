import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../shared/common/result/app_result.dart';
import '../../../application/usecases/medication_usecases.dart';
import '../../../domain/entities/medication.dart';
import 'medication_management_event.dart';
import 'medication_management_state.dart';

/// Lists and maintains the medications of one adult. Changes are serialized: an operation
/// started while another is in flight is ignored, and every receipt replaces only its row.
final class MedicationManagementBloc
    extends Bloc<MedicationManagementEvent, MedicationManagementState> {
  MedicationManagementBloc({
    required this._list,
    required this._update,
    required this._deactivate,
    required this._reactivate,
    required this.olderAdultId,
  }) : super(const MedicationManagementState()) {
    on<MedicationsRequested>(_load);
    on<MedicationEdited>(
      (event, emit) => _change(
        emit,
        () => _update(event.medicationId, event.name, event.presentation),
        MedicationNotice.updated,
      ),
    );
    on<MedicationDeactivated>(
      (event, emit) => _change(
        emit,
        () => _deactivate(event.medicationId),
        MedicationNotice.deactivated,
      ),
    );
    on<MedicationReactivated>(
      (event, emit) => _change(
        emit,
        () => _reactivate(event.medicationId),
        MedicationNotice.reactivated,
      ),
    );
  }

  final ListMedications _list;
  final UpdateMedication _update;
  final DeactivateMedication _deactivate;
  final ReactivateMedication _reactivate;
  final String olderAdultId;

  Future<void> _load(
    MedicationsRequested event,
    Emitter<MedicationManagementState> emit,
  ) async {
    if (state.busy) return;
    emit(MedicationManagementState(medications: state.medications));
    final result = await _list(olderAdultId);
    if (emit.isDone) return;
    emit(switch (result) {
      AppSuccess<List<Medication>>(:final value) => MedicationManagementState(
        status: MedicationManagementStatus.ready,
        medications: value,
      ),
      AppFailure<List<Medication>>(:final code) => MedicationManagementState(
        status: MedicationManagementStatus.failure,
        medications: state.medications,
        errorCode: code,
      ),
    });
  }

  Future<void> _change(
    Emitter<MedicationManagementState> emit,
    Future<AppResult<Medication>> Function() operation,
    MedicationNotice notice,
  ) async {
    if (state.busy || state.status == MedicationManagementStatus.loading) {
      return;
    }
    emit(state.copyWith(busy: true));
    final result = await operation();
    if (emit.isDone) return;
    switch (result) {
      case AppSuccess<Medication>(:final value):
        if (value.olderAdultId != olderAdultId) {
          emit(state.copyWith(busy: false, errorCode: 'INVALID_RESPONSE'));
          return;
        }
        emit(
          state.copyWith(
            busy: false,
            notice: notice,
            medications: [
              for (final item in state.medications)
                item.id == value.id ? value : item,
            ],
          ),
        );
      case AppFailure<Medication>(:final code):
        emit(state.copyWith(busy: false, errorCode: code));
    }
  }
}
