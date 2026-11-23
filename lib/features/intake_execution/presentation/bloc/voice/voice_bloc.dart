import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../shared/common/result/app_result.dart';
import '../../../application/ports/voice_recorder.dart';
import '../../../application/readmodels/voice_confirmation_result.dart';
import '../../../application/usecases/confirm_intake_by_voice.dart';
import '../../../application/usecases/get_intake_detail.dart';
import '../../../application/usecases/get_next_intake.dart';
import '../../../domain/entities/intake.dart';
import '../dose/dose_state.dart';
import 'voice_event.dart';
import 'voice_state.dart';

/// Records one spoken confirmation and shows the server's decision (US-06,
/// TS-11). Listening stops by itself after [maxListening]; audio is dropped
/// when the attempt is cancelled or the screen closes.
final class VoiceBloc extends Bloc<VoiceEvent, VoiceState> {
  VoiceBloc({
    required this.intakeId,
    required this._detail,
    required this._recorder,
    required this._confirm,
    required this._next,
    this.maxListening = const Duration(seconds: 8),
  }) : super(const VoiceState()) {
    on<VoiceRequested>(_load);
    on<VoiceStarted>(_start);
    on<VoiceStopped>(_stop);
    on<VoiceCancelled>(_cancel);
  }

  final String intakeId;
  final GetIntakeDetail _detail;
  final VoiceRecorder _recorder;
  final ConfirmIntakeByVoice _confirm;
  final GetNextIntake _next;
  final Duration maxListening;
  Timer? _limit;
  String _language = 'es-419';

  Future<void> _load(VoiceRequested event, Emitter<VoiceState> emit) async {
    if (state.phase case VoicePhase.recording || VoicePhase.processing) return;
    emit(const VoiceState());
    final result = await _detail(intakeId);
    if (emit.isDone) return;
    emit(switch (result) {
      AppSuccess(:final value) => VoiceState(
        phase: VoicePhase.ready,
        intake: value,
      ),
      AppFailure(:final code) => VoiceState(
        phase: VoicePhase.failure,
        errorCode: code,
      ),
    });
  }

  Future<void> _start(VoiceStarted event, Emitter<VoiceState> emit) async {
    if (!state.canStart) return;
    _language = event.language;
    final started = await _recorder.start();
    if (emit.isDone) return;
    switch (started) {
      case AppSuccess():
        emit(state.copyWith(phase: VoicePhase.recording));
        _limit = Timer(maxListening, () {
          if (!isClosed) add(const VoiceStopped());
        });
      case AppFailure(code: 'MICROPHONE_PERMISSION_DENIED'):
        emit(state.copyWith(phase: VoicePhase.permissionDenied));
      case AppFailure():
        emit(state.copyWith(phase: VoicePhase.unavailable));
    }
  }

  Future<void> _stop(VoiceStopped event, Emitter<VoiceState> emit) async {
    if (state.phase != VoicePhase.recording) return;
    _limit?.cancel();
    emit(state.copyWith(phase: VoicePhase.processing));
    final recording = await _recorder.finish();
    if (emit.isDone) return;
    if (recording case AppFailure()) {
      emit(state.copyWith(phase: VoicePhase.notRecognized));
      return;
    }
    final audio = (recording as AppSuccess).value;
    final result = await _confirm(intakeId, audio, _language);
    if (emit.isDone) return;
    switch (result) {
      case AppSuccess(:final value) when value.intake != null:
        final intake = value.intake!;
        await _finish(
          emit,
          intake,
          value.recognition == VoiceRecognition.alreadyConfirmed
              ? ConfirmationOutcome.alreadyConfirmed
              : intake.status == IntakeStatus.late
              ? ConfirmationOutcome.late
              : ConfirmationOutcome.confirmed,
        );
      case AppSuccess(:final value)
          when value.recognition == VoiceRecognition.providerUnavailable:
        emit(state.copyWith(phase: VoicePhase.unavailable));
      case AppSuccess():
        emit(state.copyWith(phase: VoicePhase.notRecognized));
      case AppFailure(code: 'VOICE_CONFIRMATION_DISABLED'):
        emit(state.copyWith(phase: VoicePhase.disabled));
      case AppFailure(code: 'NETWORK_UNAVAILABLE'):
        emit(state.copyWith(phase: VoicePhase.offline));
      case AppFailure(code: 'INTAKE_NOT_CONFIRMABLE'):
        await _reconcile(emit);
      case AppFailure(:final code):
        emit(state.copyWith(phase: VoicePhase.unavailable, errorCode: code));
    }
  }

  Future<void> _cancel(VoiceCancelled event, Emitter<VoiceState> emit) async {
    _limit?.cancel();
    if (state.phase != VoicePhase.recording) return;
    await _recorder.cancel();
    if (!emit.isDone) emit(state.copyWith(phase: VoicePhase.ready));
  }

  /// Another device may have confirmed it; a failed read proves nothing.
  Future<void> _reconcile(Emitter<VoiceState> emit) async {
    final reread = await _detail(intakeId);
    if (emit.isDone) return;
    switch (reread) {
      case AppSuccess(:final value) when value.taken:
        await _finish(emit, value, ConfirmationOutcome.alreadyConfirmed);
      case AppSuccess(:final value) when value.status == IntakeStatus.omitted:
        await _finish(emit, value, ConfirmationOutcome.omissionPreserved);
      case _:
        emit(
          state.copyWith(
            phase: VoicePhase.unavailable,
            errorCode: 'INTAKE_NOT_CONFIRMABLE',
          ),
        );
    }
  }

  Future<void> _finish(
    Emitter<VoiceState> emit,
    Intake intake,
    ConfirmationOutcome outcome,
  ) async {
    final next = await _next();
    if (emit.isDone) return;
    emit(
      VoiceState(
        phase: VoicePhase.ready,
        intake: intake,
        outcome: outcome,
        next: switch (next) {
          AppSuccess(:final value) when value?.id != intakeId => value,
          _ => null,
        },
      ),
    );
  }

  @override
  Future<void> close() async {
    _limit?.cancel();
    await _recorder.cancel();
    return super.close();
  }
}
