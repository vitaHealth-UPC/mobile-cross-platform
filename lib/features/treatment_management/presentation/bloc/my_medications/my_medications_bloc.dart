import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../shared/common/result/app_result.dart';
import '../../../application/readmodels/treatment_readmodels.dart';
import '../../../application/usecases/treatment_usecases.dart';

/// Intents of the adult medication catalog.
sealed class MyMedicationsEvent {
  const MyMedicationsEvent();
}

final class MyMedicationsRequested extends MyMedicationsEvent {
  const MyMedicationsRequested();
}

/// Switches between active treatments and the history of inactive ones.
final class MyMedicationsHistorySelected extends MyMedicationsEvent {
  const MyMedicationsHistorySelected(this.history);
  final bool history;
}

enum MyMedicationsStatus { loading, ready, failure }

/// Catalog and next dose; a failed lookup is never presented as an empty agenda.
final class MyMedicationsState {
  const MyMedicationsState({
    this.status = MyMedicationsStatus.loading,
    this.medications = const [],
    this.nextDose,
    this.history = false,
    this.errorCode,
    this.scheduleError,
  });

  final MyMedicationsStatus status;
  final List<MyMedication> medications;
  final MedicationNextDose? nextDose;
  final bool history;
  final String? errorCode;
  final String? scheduleError;

  List<MyMedication> get active =>
      medications.where((item) => item.active).toList();
  List<MyMedication> get inactive =>
      medications.where((item) => !item.active).toList();
}

/// Loads the adult catalog together with the next intake; only the latest request emits.
final class MyMedicationsBloc
    extends Bloc<MyMedicationsEvent, MyMedicationsState> {
  MyMedicationsBloc({required this._overview})
    : super(const MyMedicationsState()) {
    on<MyMedicationsRequested>(_load);
    on<MyMedicationsHistorySelected>(
      (event, emit) => emit(
        MyMedicationsState(
          status: state.status,
          medications: state.medications,
          nextDose: state.nextDose,
          history: event.history,
          errorCode: state.errorCode,
          scheduleError: state.scheduleError,
        ),
      ),
    );
  }

  final GetMyMedicationsOverview _overview;
  int _revision = 0;

  Future<void> _load(
    MyMedicationsRequested event,
    Emitter<MyMedicationsState> emit,
  ) async {
    final revision = ++_revision;
    emit(MyMedicationsState(history: state.history));
    final result = await _overview();
    if (revision != _revision || emit.isDone) return;
    emit(switch (result) {
      AppSuccess<MyMedicationsOverview>(:final value) => MyMedicationsState(
        status: MyMedicationsStatus.ready,
        medications: value.medications,
        nextDose: value.nextDose,
        scheduleError: value.scheduleError,
        history: state.history,
      ),
      AppFailure<MyMedicationsOverview>(:final code) => MyMedicationsState(
        status: MyMedicationsStatus.failure,
        history: state.history,
        errorCode: code,
      ),
    });
  }
}
