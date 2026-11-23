import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../shared/common/result/app_result.dart';
import '../../../application/usecases/confirm_intake.dart';
import '../../../application/usecases/get_intake_detail.dart';
import '../../../application/usecases/get_next_intake.dart';
import '../../../domain/entities/intake.dart';
import 'dose_event.dart';
import 'dose_state.dart';

/// Shows one dose and confirms it by touch (US-06, US-21, US-23).
/// A rejected confirmation is reread before showing an outcome: another
/// device may have confirmed it, and a failed read never proves an omission.
final class DoseBloc extends Bloc<DoseEvent, DoseState> {
  DoseBloc({
    required this.intakeId,
    required this._detail,
    required this._confirm,
    required this._next,
  }) : super(const DoseState()) {
    on<DoseRequested>(_load);
    on<DoseConfirmRequested>(_confirmDose);
  }

  final String intakeId;
  final GetIntakeDetail _detail;
  final ConfirmIntake _confirm;
  final GetNextIntake _next;

  Future<void> _load(DoseRequested event, Emitter<DoseState> emit) async {
    if (state.confirming) return;
    emit(const DoseState());
    final result = await _detail(intakeId);
    if (emit.isDone) return;
    emit(switch (result) {
      AppSuccess(:final value) => DoseState(
        status: DoseStatus.ready,
        intake: value,
      ),
      AppFailure(:final code) => DoseState(
        status: DoseStatus.failure,
        errorCode: code,
      ),
    });
  }

  Future<void> _confirmDose(
    DoseConfirmRequested event,
    Emitter<DoseState> emit,
  ) async {
    if (!state.canConfirm) return;
    final current = state.intake;
    emit(
      DoseState(status: DoseStatus.ready, intake: current, confirming: true),
    );
    final result = await _confirm(intakeId);
    if (emit.isDone) return;
    switch (result) {
      case AppSuccess(:final value):
        final outcome = switch ((value.alreadyConfirmed, value.intake.status)) {
          (true, _) => ConfirmationOutcome.alreadyConfirmed,
          (false, IntakeStatus.late) => ConfirmationOutcome.late,
          _ => ConfirmationOutcome.confirmed,
        };
        await _finish(emit, value.intake, outcome);
      case AppFailure(code: 'INTAKE_NOT_CONFIRMABLE'):
        await _reconcile(emit, current);
      case AppFailure(:final code):
        emit(
          DoseState(status: DoseStatus.ready, intake: current, errorCode: code),
        );
    }
  }

  Future<void> _reconcile(Emitter<DoseState> emit, Intake? current) async {
    final reread = await _detail(intakeId);
    if (emit.isDone) return;
    switch (reread) {
      case AppSuccess(:final value) when value.taken:
        await _finish(emit, value, ConfirmationOutcome.alreadyConfirmed);
      case AppSuccess(:final value) when value.status == IntakeStatus.omitted:
        await _finish(emit, value, ConfirmationOutcome.omissionPreserved);
      case AppSuccess(:final value):
        emit(
          DoseState(
            status: DoseStatus.ready,
            intake: value,
            errorCode: 'INTAKE_NOT_CONFIRMABLE',
          ),
        );
      case AppFailure():
        emit(
          DoseState(
            status: DoseStatus.ready,
            intake: current,
            errorCode: 'INTAKE_NOT_CONFIRMABLE',
          ),
        );
    }
  }

  /// The next dose is optional context for the result screen.
  Future<void> _finish(
    Emitter<DoseState> emit,
    Intake intake,
    ConfirmationOutcome outcome,
  ) async {
    final next = await _next();
    if (emit.isDone) return;
    emit(
      DoseState(
        status: DoseStatus.ready,
        intake: intake,
        outcome: outcome,
        next: switch (next) {
          AppSuccess(:final value) when value?.id != intakeId => value,
          _ => null,
        },
      ),
    );
  }
}
