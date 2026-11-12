import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../shared/common/result/app_result.dart';
import '../../../application/readmodels/treatment_readmodels.dart';
import '../../../application/usecases/regimen_usecases.dart';
import '../../../application/usecases/treatment_usecases.dart';
import '../../../domain/entities/treatment.dart';
import '../../../domain/value_objects/regimen_text.dart';
import '../../../domain/value_objects/treatment_status.dart';
import 'treatment_setup_event.dart';
import 'treatment_setup_state.dart';

/// Guides a caregiver from a registered medication to an active treatment.
/// Each step validates with the same domain values the server enforces; nothing reaches the
/// server except the draft creation and the final configure-and-activate.
final class TreatmentSetupBloc
    extends Bloc<TreatmentSetupEvent, TreatmentSetupState> {
  TreatmentSetupBloc({
    required this._create,
    required this._basics,
    required this._schedule,
    required this._reminder,
    required this._read,
    required this._configure,
    required this._changeStatus,
    required this.olderAdultId,
    required this.medicationId,
  }) : super(const TreatmentSetupState()) {
    on<TreatmentDraftSubmitted>(_draft);
    on<RegimenBasicsSubmitted>(_regimen);
    on<ScheduleSubmitted>(_scheduled);
    on<ReminderSubmitted>(_reminders);
    on<TreatmentSetupBackRequested>(_back);
    on<TreatmentActivationRequested>(_activate);
  }

  final CreateTreatment _create;
  final SetDoseFrequency _basics;
  final SetScheduleInstructions _schedule;
  final SetReminderPolicy _reminder;
  final GetTreatmentDetail _read;
  final ConfigureTreatment _configure;
  final ChangeTreatmentStatus _changeStatus;
  final String olderAdultId;
  final String medicationId;

  Future<void> _draft(
    TreatmentDraftSubmitted event,
    Emitter<TreatmentSetupState> emit,
  ) async {
    if (state.loading) return;
    // A draft that already exists is reused, so going back never duplicates it.
    if (state.treatmentId != null) {
      emit(state.copyWith(step: TreatmentSetupStep.regimen));
      return;
    }
    emit(state.copyWith(loading: true));
    final result = await _create(olderAdultId, event.name);
    if (emit.isDone) return;
    switch (result) {
      case AppSuccess<Treatment>(:final value):
        if (value.olderAdultId != olderAdultId) {
          emit(state.copyWith(loading: false, errorCode: 'INVALID_RESPONSE'));
          return;
        }
        emit(
          state.copyWith(
            loading: false,
            treatmentId: value.id,
            treatmentName: value.name,
            step: TreatmentSetupStep.regimen,
          ),
        );
      case AppFailure<Treatment>(:final code):
        emit(state.copyWith(loading: false, errorCode: code));
    }
  }

  void _regimen(
    RegimenBasicsSubmitted event,
    Emitter<TreatmentSetupState> emit,
  ) {
    switch (_basics(event.dose, event.frequency)) {
      case AppSuccess<RegimenBasics>(:final value):
        emit(
          state.copyWith(
            dose: value.dose.value,
            frequency: value.frequency.value,
            step: TreatmentSetupStep.schedule,
          ),
        );
      case AppFailure<RegimenBasics>(:final code):
        emit(state.copyWith(errorCode: code));
    }
  }

  void _scheduled(ScheduleSubmitted event, Emitter<TreatmentSetupState> emit) {
    switch (_schedule(event.scheduleText, event.instructions)) {
      case AppSuccess<ScheduleInstructions>(:final value):
        emit(
          state.copyWith(
            scheduleText: value.schedule.times.map((t) => '$t').join(','),
            instructions: value.instructions.value,
            step: TreatmentSetupStep.reminders,
          ),
        );
      case AppFailure<ScheduleInstructions>(:final code):
        emit(state.copyWith(errorCode: code));
    }
  }

  void _reminders(ReminderSubmitted event, Emitter<TreatmentSetupState> emit) {
    // Blank keeps the system default follow-up.
    if (event.delayMinutes.trim().isEmpty) {
      emit(
        state.copyWith(clearFollowUp: true, step: TreatmentSetupStep.review),
      );
      return;
    }
    switch (_reminder(event.delayMinutes)) {
      case AppSuccess<ReminderDelayMinutes>(:final value):
        emit(
          state.copyWith(
            followUpDelayMinutes: value.value,
            step: TreatmentSetupStep.review,
          ),
        );
      case AppFailure<ReminderDelayMinutes>(:final code):
        emit(state.copyWith(errorCode: code));
    }
  }

  void _back(
    TreatmentSetupBackRequested event,
    Emitter<TreatmentSetupState> emit,
  ) {
    if (state.loading || state.activated || state.step.index == 0) return;
    emit(state.copyWith(step: TreatmentSetupStep.values[state.step.index - 1]));
  }

  Future<void> _activate(
    TreatmentActivationRequested event,
    Emitter<TreatmentSetupState> emit,
  ) async {
    final id = state.treatmentId;
    if (state.loading ||
        state.activated ||
        id == null ||
        state.step != TreatmentSetupStep.review) {
      return;
    }
    emit(state.copyWith(loading: true, configurationIncomplete: false));
    // Recheck the server before mutating a restored or stale wizard.
    final latest = await _read(id);
    if (emit.isDone) return;
    switch (latest) {
      case AppFailure<TreatmentDetail>(:final code):
        emit(state.copyWith(loading: false, errorCode: code));
        return;
      case AppSuccess<TreatmentDetail>(:final value):
        if (value.olderAdultId != olderAdultId) {
          emit(state.copyWith(loading: false, errorCode: 'INVALID_RESPONSE'));
          return;
        }
        if (value.status != TreatmentStatus.draft) {
          emit(state.copyWith(loading: false, activated: true));
          return;
        }
    }
    final configured = await _configure(
      id,
      medicationId,
      RegimenDraft(
        dose: state.dose,
        frequency: state.frequency,
        scheduleText: state.scheduleText,
        instructions: state.instructions,
        followUpDelayMinutes: state.followUpDelayMinutes,
      ),
    );
    if (emit.isDone) return;
    if (configured case AppFailure<Treatment>(:final code)) {
      emit(
        state.copyWith(
          loading: false,
          errorCode: code,
          configurationIncomplete:
              code == 'INVALID_TREATMENT_CONFIGURATION' ||
              code == 'REQUEST_VALIDATION_FAILED',
        ),
      );
      return;
    }
    final activated = await _changeStatus(
      id,
      TreatmentLifecycleAction.activate,
    );
    if (emit.isDone) return;
    emit(switch (activated) {
      AppSuccess<Treatment>() => state.copyWith(
        loading: false,
        activated: true,
      ),
      AppFailure<Treatment>(:final code) => state.copyWith(
        loading: false,
        errorCode: code,
      ),
    });
  }
}
