import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../shared/common/result/app_result.dart';
import '../../../application/readmodels/treatment_readmodels.dart';
import '../../../application/usecases/medication_usecases.dart';
import '../../../application/usecases/treatment_usecases.dart';
import '../../../domain/entities/medication.dart';
import '../../../domain/entities/treatment.dart';
import 'treatment_management_event.dart';
import 'treatment_management_state.dart';

/// Failures after which the screen cannot keep offering management actions.
const _invalidating = {
  'ACCESS_DENIED',
  'AUTHENTICATION_REQUIRED',
  'SESSION_CHANGED',
  'RESOURCE_NOT_FOUND',
};

/// Reads one treatment and applies lifecycle, regimen and availability changes to it.
/// Every receipt is checked against the adult and medication this screen was opened for.
final class TreatmentManagementBloc
    extends Bloc<TreatmentManagementEvent, TreatmentManagementState> {
  TreatmentManagementBloc({
    required this._detail,
    required this._medications,
    required this._configure,
    required this._changeStatus,
    required this._reactivate,
    required this._deactivate,
    required this.treatmentId,
    required this.olderAdultId,
  }) : super(const TreatmentManagementState()) {
    on<TreatmentManagementRequested>(_load);
    on<TreatmentPauseRequested>(
      (event, emit) => _status(emit, TreatmentLifecycleAction.pause),
    );
    on<TreatmentResumeRequested>(
      (event, emit) => _status(emit, TreatmentLifecycleAction.resume),
    );
    on<RegimenEdited>(_editRegimen);
    on<TreatmentMedicationReactivated>(_reactivateMedication);
    on<TreatmentMedicationDeactivated>(_deactivateMedication);
  }

  final GetTreatmentDetail _detail;
  final ListMedications _medications;
  final ConfigureTreatment _configure;
  final ChangeTreatmentStatus _changeStatus;
  final ReactivateMedication _reactivate;
  final DeactivateMedication _deactivate;
  final String treatmentId;
  final String olderAdultId;
  int _revision = 0;

  TreatmentManagementState _failed(String code) => TreatmentManagementState(
    status: TreatmentManagementStatus.failure,
    errorCode: code,
  );

  Future<void> _load(
    TreatmentManagementRequested event,
    Emitter<TreatmentManagementState> emit,
  ) async {
    if (state.busy) return;
    final revision = ++_revision;
    emit(const TreatmentManagementState());
    final result = await _detail(treatmentId);
    if (revision != _revision || emit.isDone) return;
    if (result is AppFailure<TreatmentDetail>) {
      emit(_failed(result.code));
      return;
    }
    final detail = (result as AppSuccess<TreatmentDetail>).value;
    if (detail.olderAdultId != olderAdultId) {
      emit(_failed('INVALID_RESPONSE'));
      return;
    }
    // A draft has no regimen to manage: it is shown read-only as incomplete.
    if (detail.isDraft || detail.medicationId == null) {
      emit(
        TreatmentManagementState(
          status: TreatmentManagementStatus.ready,
          detail: detail,
        ),
      );
      return;
    }
    final catalog = await _medications(olderAdultId);
    if (revision != _revision || emit.isDone) return;
    if (catalog is AppFailure<List<Medication>>) {
      emit(_failed(catalog.code));
      return;
    }
    final entries = (catalog as AppSuccess<List<Medication>>).value;
    final medication = entries
        .where((item) => item.id == detail.medicationId)
        .firstOrNull;
    if (medication == null) {
      emit(_failed('INVALID_RESPONSE'));
      return;
    }
    emit(
      TreatmentManagementState(
        status: TreatmentManagementStatus.ready,
        detail: detail,
        medication: medication,
        activeMedicationCount: entries.where((item) => item.active).length,
      ),
    );
  }

  Future<void> _status(
    Emitter<TreatmentManagementState> emit,
    TreatmentLifecycleAction action,
  ) async {
    if (state.busy || !state.manageable || state.medicationInactive) return;
    emit(state.copyWith(busy: true));
    final result = await _changeStatus(treatmentId, action);
    if (emit.isDone) return;
    switch (result) {
      case AppSuccess<Treatment>(:final value):
        final detail = state.detail!;
        emit(
          state.copyWith(
            busy: false,
            detail: TreatmentDetail(
              id: detail.id,
              olderAdultId: detail.olderAdultId,
              name: detail.name,
              status: value.status,
              medicationId: detail.medicationId,
              dose: detail.dose,
              frequency: detail.frequency,
              scheduledTimes: detail.scheduledTimes,
              instructions: detail.instructions,
              reminderLeadMinutes: detail.reminderLeadMinutes,
              followUpDelayMinutes: detail.followUpDelayMinutes,
              recurrenceZone: detail.recurrenceZone,
            ),
          ),
        );
      case AppFailure<Treatment>(:final code):
        _fail(emit, code);
    }
  }

  Future<void> _editRegimen(
    RegimenEdited event,
    Emitter<TreatmentManagementState> emit,
  ) async {
    final detail = state.detail;
    if (state.busy ||
        detail == null ||
        !state.manageable ||
        state.medicationInactive) {
      return;
    }
    final blank = event.delayMinutes.trim().isEmpty;
    final minutes = int.tryParse(event.delayMinutes.trim());
    if (!blank && (minutes == null || minutes < 0 || minutes > 1440)) {
      emit(state.copyWith(errorCode: 'INVALID_REMINDER_DELAY'));
      return;
    }
    emit(state.copyWith(busy: true));
    // The latest lead time is preserved: editing never changes ACTIVE/PAUSED state.
    final latest = await _detail(treatmentId);
    if (emit.isDone) return;
    if (latest is AppFailure<TreatmentDetail>) {
      _fail(emit, latest.code);
      return;
    }
    final fresh = (latest as AppSuccess<TreatmentDetail>).value;
    if (fresh.olderAdultId != olderAdultId ||
        fresh.medicationId != detail.medicationId) {
      emit(_failed('INVALID_RESPONSE'));
      return;
    }
    final result = await _configure(
      treatmentId,
      detail.medicationId!,
      RegimenDraft(
        dose: event.dose,
        frequency: event.frequency,
        scheduleText: event.scheduleText,
        instructions: event.instructions,
        followUpDelayMinutes: blank ? null : minutes,
        reminderLeadMinutes: fresh.reminderLeadMinutes ?? 0,
      ),
    );
    if (emit.isDone) return;
    if (result is AppFailure<Treatment>) {
      _fail(emit, result.code);
      return;
    }
    // Reload so the screen shows exactly what the server stored.
    final reread = await _detail(treatmentId);
    if (emit.isDone) return;
    if (reread is AppSuccess<TreatmentDetail> &&
        reread.value.olderAdultId == olderAdultId) {
      emit(
        TreatmentManagementState(
          status: TreatmentManagementStatus.ready,
          detail: reread.value,
          medication: state.medication,
          activeMedicationCount: state.activeMedicationCount,
          regimenSaved: true,
        ),
      );
    } else {
      emit(state.copyWith(busy: false, errorCode: 'INVALID_RESPONSE'));
    }
  }

  Future<void> _reactivateMedication(
    TreatmentMedicationReactivated event,
    Emitter<TreatmentManagementState> emit,
  ) => _changeAvailability(
    emit,
    state.medicationInactive,
    (id) => _reactivate(id),
    true,
  );

  Future<void> _deactivateMedication(
    TreatmentMedicationDeactivated event,
    Emitter<TreatmentManagementState> emit,
  ) => _changeAvailability(
    emit,
    state.medication?.active == true,
    (id) => _deactivate(id),
    false,
  );

  Future<void> _changeAvailability(
    Emitter<TreatmentManagementState> emit,
    bool applicable,
    Future<AppResult<Medication>> Function(String id) operation,
    bool expectedActive,
  ) async {
    final medication = state.medication;
    if (state.busy || medication == null || !applicable) return;
    emit(state.copyWith(busy: true));
    final result = await operation(medication.id);
    if (emit.isDone) return;
    switch (result) {
      case AppSuccess<Medication>(:final value):
        if (value.id != medication.id ||
            value.olderAdultId != olderAdultId ||
            value.active != expectedActive) {
          emit(state.copyWith(busy: false, errorCode: 'INVALID_RESPONSE'));
          return;
        }
        final others =
            (state.activeMedicationCount ?? 0) - (medication.active ? 1 : 0);
        emit(
          state.copyWith(
            busy: false,
            medication: value,
            activeMedicationCount: others + (value.active ? 1 : 0),
          ),
        );
      case AppFailure<Medication>(:final code):
        _fail(emit, code);
    }
  }

  void _fail(Emitter<TreatmentManagementState> emit, String code) {
    emit(
      _invalidating.contains(code)
          ? _failed(code)
          : state.copyWith(busy: false, errorCode: code),
    );
  }
}
