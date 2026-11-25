import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../shared/common/result/app_result.dart';
import '../../../application/readmodels/treatment_detail.dart';
import '../../../application/usecases/change_treatment_status.dart';
import '../../../application/usecases/configure_treatment.dart';
import '../../../application/usecases/create_treatment.dart';
import '../../../application/usecases/get_treatment_detail.dart';
import '../../../application/usecases/set_dose_frequency.dart';
import '../../../application/usecases/set_reminder_policy.dart';
import '../../../application/usecases/set_schedule_instructions.dart';
import '../../../domain/entities/treatment.dart';
import '../../../domain/value_objects/regimen_text.dart';
import '../../../domain/value_objects/treatment_status.dart';
import 'treatment_setup_event.dart';
import 'treatment_setup_state.dart';

/// Guides a caregiver from registered medications to one active treatment.
///
/// A treatment can hold several medications (for example a diabetes plan);
/// each gets its own regimen. Each step validates with the same domain values
/// the server enforces. Nothing reaches the server until activation, which
/// creates one draft per medication sharing the plan of the first, saves its
/// regimen and activates it. A retry reuses the drafts already created and
/// skips the medications already active, so nothing is duplicated.
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
    List<SetupMedication> medications = const [],
    this.calendarZone,
  }) : super(TreatmentSetupState(medications: List.unmodifiable(medications))) {
    on<TreatmentDraftSubmitted>(_details);
    on<TreatmentMedicationsChanged>(_medications);
    on<TreatmentRegimensSubmitted>(_regimens);
    on<TreatmentRegimenSubmitted>(
      (event, emit) => _regimens(
        TreatmentRegimensSubmitted({
          if (state.medications.isNotEmpty)
            state.medications.first.id: RegimenInput(
              event.dose,
              event.frequency,
              event.scheduleText,
              event.instructions,
            ),
        }),
        emit,
      ),
    );
    on<RegimenBasicsSubmitted>(_basicsStep);
    on<ScheduleSubmitted>(_scheduleStep);
    on<ReminderSubmitted>(_reminders);
    on<TreatmentSetupBackRequested>(_back);
    on<TreatmentActivationRequested>(_activate);
    on<TreatmentConfigurationCorrectionRequested>((event, emit) {
      if (!state.loading && state.configurationIncomplete) {
        emit(
          state.copyWith(
            step: TreatmentSetupStep.regimen,
            configurationIncomplete: false,
          ),
        );
      }
    });
  }

  final CreateTreatment _create;
  final SetDoseFrequency _basics;
  final SetScheduleInstructions _schedule;
  final SetReminderPolicy _reminder;
  final GetTreatmentDetail _read;
  final ConfigureTreatment _configure;
  final ChangeTreatmentStatus _changeStatus;
  final String olderAdultId;
  final String? calendarZone;

  /// Medications can change until the first draft is created on the server.
  bool get _locked => state.treatmentIds.isNotEmpty;

  void _details(
    TreatmentDraftSubmitted event,
    Emitter<TreatmentSetupState> emit,
  ) {
    if (state.loading) return;
    final name = event.name.trim();
    if (name.isEmpty || name.length > 160) {
      emit(state.copyWith(errorCode: 'REQUIRED_FIELDS_MISSING'));
      return;
    }
    if (state.medications.isEmpty) {
      emit(state.copyWith(errorCode: 'MEDICATION_REQUIRED'));
      return;
    }
    emit(
      state.copyWith(
        treatmentName: _locked ? state.treatmentName : name,
        step: TreatmentSetupStep.regimen,
      ),
    );
  }

  void _medications(
    TreatmentMedicationsChanged event,
    Emitter<TreatmentSetupState> emit,
  ) {
    if (state.loading || _locked) return;
    final unique = <String, SetupMedication>{
      for (final medication in event.medications) medication.id: medication,
    };
    emit(
      state.copyWith(
        medications: List.unmodifiable(unique.values),
        regimens: {
          for (final entry in state.regimens.entries)
            if (unique.containsKey(entry.key)) entry.key: entry.value,
        },
      ),
    );
  }

  void _regimens(
    TreatmentRegimensSubmitted event,
    Emitter<TreatmentSetupState> emit,
  ) {
    if (state.loading ||
        (state.step != TreatmentSetupStep.regimen &&
            state.step != TreatmentSetupStep.schedule)) {
      return;
    }
    final validated = <String, SetupRegimen>{};
    for (final medication in state.medications) {
      final input = event.regimens[medication.id];
      if (input == null) {
        emit(
          state.copyWith(
            errorCode: 'INVALID_TREATMENT_CONFIGURATION',
            errorMedicationId: medication.id,
          ),
        );
        return;
      }
      final basics = _basics(input.dose, input.frequency);
      final schedule = _schedule(input.scheduleText, input.instructions);
      final failure = switch ((basics, schedule)) {
        (AppFailure<RegimenBasics>(:final code), _) => code,
        (_, AppFailure<ScheduleInstructions>(:final code)) => code,
        _ => null,
      };
      if (failure != null) {
        emit(
          state.copyWith(errorCode: failure, errorMedicationId: medication.id),
        );
        return;
      }
      final regimen = (basics as AppSuccess<RegimenBasics>).value;
      final times = (schedule as AppSuccess<ScheduleInstructions>).value;
      if (!regimen.frequency.matchesMinutes(
        times.schedule.times.map((t) => t.hour * 60 + t.minute),
      )) {
        emit(
          state.copyWith(
            errorCode: 'SCHEDULE_FREQUENCY_MISMATCH',
            errorMedicationId: medication.id,
          ),
        );
        return;
      }
      validated[medication.id] = SetupRegimen(
        dose: regimen.dose.value,
        frequency: regimen.frequency.value,
        scheduleText: times.schedule.times.join(','),
        instructions: times.instructions.value,
      );
    }
    emit(
      state.copyWith(
        regimens: validated,
        configurationIncomplete: false,
        step: TreatmentSetupStep.reminders,
      ),
    );
  }

  /// Dose and frequency of the first medication, kept until its times arrive.
  void _basicsStep(
    RegimenBasicsSubmitted event,
    Emitter<TreatmentSetupState> emit,
  ) {
    if (state.loading || state.medications.isEmpty) return;
    switch (_basics(event.dose, event.frequency)) {
      case AppSuccess<RegimenBasics>(:final value):
        final id = state.medications.first.id;
        final previous = state.regimens[id] ?? const SetupRegimen();
        emit(
          state.copyWith(
            regimens: {
              ...state.regimens,
              id: SetupRegimen(
                dose: value.dose.value,
                frequency: value.frequency.value,
                scheduleText: previous.scheduleText,
                instructions: previous.instructions,
              ),
            },
            step: TreatmentSetupStep.schedule,
          ),
        );
      case AppFailure<RegimenBasics>(:final code):
        emit(state.copyWith(errorCode: code));
    }
  }

  void _scheduleStep(
    ScheduleSubmitted event,
    Emitter<TreatmentSetupState> emit,
  ) {
    if (state.loading || state.medications.isEmpty) return;
    final id = state.medications.first.id;
    final regimen = state.regimens[id] ?? const SetupRegimen();
    switch (_schedule(event.scheduleText, event.instructions)) {
      case AppSuccess<ScheduleInstructions>(:final value):
        final frequency = Frequency.tryParse(regimen.frequency);
        if (frequency == null ||
            !frequency.matchesMinutes(
              value.schedule.times.map((t) => t.hour * 60 + t.minute),
            )) {
          emit(state.copyWith(errorCode: 'SCHEDULE_FREQUENCY_MISMATCH'));
          return;
        }
        emit(
          state.copyWith(
            regimens: {
              ...state.regimens,
              id: SetupRegimen(
                dose: regimen.dose,
                frequency: regimen.frequency,
                scheduleText: value.schedule.times.join(','),
                instructions: value.instructions.value,
              ),
            },
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
    emit(
      state.copyWith(
        step: switch (state.step) {
          TreatmentSetupStep.reminders => TreatmentSetupStep.regimen,
          TreatmentSetupStep.schedule => TreatmentSetupStep.regimen,
          final step => TreatmentSetupStep.values[step.index - 1],
        },
      ),
    );
  }

  Future<void> _activate(
    TreatmentActivationRequested event,
    Emitter<TreatmentSetupState> emit,
  ) async {
    if (state.loading ||
        state.activated ||
        state.step != TreatmentSetupStep.review ||
        state.medications.isEmpty) {
      return;
    }
    emit(state.copyWith(loading: true, configurationIncomplete: false));
    for (final medication in state.medications) {
      if (state.activatedIds.contains(medication.id)) continue;
      final failure = await _activateOne(medication, emit);
      if (emit.isDone) return;
      if (failure != null) {
        emit(
          state.copyWith(
            loading: false,
            errorCode: failure,
            errorMedicationId: medication.id,
            configurationIncomplete:
                failure == 'INVALID_TREATMENT_CONFIGURATION' ||
                failure == 'REQUEST_VALIDATION_FAILED',
          ),
        );
        return;
      }
    }
    emit(state.copyWith(loading: false, activated: true));
  }

  /// Creates (or rechecks) the draft of [medication], saves its regimen and
  /// activates it. Returns a failure code, or null when it is active.
  Future<String?> _activateOne(
    SetupMedication medication,
    Emitter<TreatmentSetupState> emit,
  ) async {
    var id = state.treatmentIds[medication.id];
    if (id == null) {
      final created = await _create(
        olderAdultId,
        state.treatmentName,
        planId: state.planId,
      );
      if (emit.isDone) return null;
      switch (created) {
        case AppFailure<Treatment>(:final code):
          return code;
        case AppSuccess<Treatment>(:final value):
          if (value.olderAdultId != olderAdultId ||
              (state.planId != null && value.planId != state.planId)) {
            return 'INVALID_RESPONSE';
          }
          id = value.id;
          emit(
            state.copyWith(
              loading: true,
              planId: state.planId ?? value.planId,
              treatmentIds: {...state.treatmentIds, medication.id: value.id},
            ),
          );
      }
    } else {
      // Recheck the server before mutating a restored or stale wizard.
      final latest = await _read(id);
      if (emit.isDone) return null;
      switch (latest) {
        case AppFailure<TreatmentDetail>(:final code):
          return code;
        case AppSuccess<TreatmentDetail>(:final value):
          if (value.olderAdultId != olderAdultId) return 'INVALID_RESPONSE';
          if (value.status == TreatmentStatus.active) {
            _markActive(medication, emit);
            return null;
          }
          if (value.status != TreatmentStatus.draft) return 'CONFLICT';
      }
    }
    final regimen = state.regimens[medication.id] ?? const SetupRegimen();
    final configured = await _configure(
      id,
      medication.id,
      RegimenDraft(
        dose: regimen.dose,
        frequency: regimen.frequency,
        scheduleText: regimen.scheduleText,
        instructions: regimen.instructions,
        followUpDelayMinutes: state.followUpDelayMinutes,
        recurrenceZone: calendarZone,
      ),
    );
    if (emit.isDone) return null;
    if (configured case AppFailure<Treatment>(:final code)) return code;
    final activated = await _changeStatus(
      id,
      TreatmentLifecycleAction.activate,
    );
    if (emit.isDone) return null;
    if (activated case AppFailure<Treatment>(:final code)) return code;
    _markActive(medication, emit);
    return null;
  }

  void _markActive(
    SetupMedication medication,
    Emitter<TreatmentSetupState> emit,
  ) => emit(
    state.copyWith(
      loading: true,
      activatedIds: {...state.activatedIds, medication.id},
    ),
  );
}
