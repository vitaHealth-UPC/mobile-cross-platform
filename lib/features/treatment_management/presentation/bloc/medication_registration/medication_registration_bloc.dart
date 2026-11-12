import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../shared/common/result/app_result.dart';
import '../../../application/usecases/medication_usecases.dart';
import '../../../domain/entities/medication.dart';
import 'medication_registration_event.dart';
import 'medication_registration_state.dart';

/// Registers one medication for the selected adult; repeated taps are ignored while saving.
final class MedicationRegistrationBloc
    extends Bloc<MedicationRegistrationEvent, MedicationRegistrationState> {
  MedicationRegistrationBloc({
    required this._register,
    required this.olderAdultId,
  }) : super(const MedicationRegistrationState()) {
    on<MedicationSubmitted>(_submit);
  }

  final RegisterMedication _register;
  final String olderAdultId;

  Future<void> _submit(
    MedicationSubmitted event,
    Emitter<MedicationRegistrationState> emit,
  ) async {
    if (state.status == MedicationRegistrationStatus.submitting ||
        state.status == MedicationRegistrationStatus.registered) {
      return;
    }
    emit(
      const MedicationRegistrationState(
        status: MedicationRegistrationStatus.submitting,
      ),
    );
    final result = await _register(
      olderAdultId,
      event.name,
      event.presentation,
    );
    if (emit.isDone) return;
    emit(switch (result) {
      AppSuccess<Medication>(:final value) => MedicationRegistrationState(
        status: MedicationRegistrationStatus.registered,
        medication: value,
      ),
      AppFailure<Medication>(:final code) => MedicationRegistrationState(
        status: MedicationRegistrationStatus.failure,
        errorCode: code,
      ),
    });
  }
}
