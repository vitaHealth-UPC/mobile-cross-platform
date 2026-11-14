import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/common/result/app_result.dart';
import '../../application/usecases/inventory_usecases.dart';
import '../../domain/entities/inventory.dart';
import 'inventory_event.dart';
import 'inventory_state.dart';

/// Stock, initial registration and replenishment of one medication
/// (US-40 to US-43). Only one write runs at a time.
final class InventoryBloc extends Bloc<InventoryEvent, InventoryState> {
  InventoryBloc({
    required this.medicationId,
    required this._read,
    required this._registerInitial,
    required this._replenish,
  }) : super(const InventoryState()) {
    on<InventoryRequested>(_load);
    on<InitialStockSubmitted>(_initial);
    on<ReplenishmentSubmitted>(_replenishment);
    on<InventoryInputChanged>(_changed);
  }

  final String medicationId;
  final GetInventory _read;
  final RegisterInitialInventory _registerInitial;
  final RegisterReplenishment _replenish;

  static const _fieldCodes = {
    'INVALID_QUANTITY': InventoryField.quantity,
    'INVALID_THRESHOLD': InventoryField.threshold,
    'INVALID_LOT': InventoryField.lot,
  };

  Future<void> _load(
    InventoryRequested event,
    Emitter<InventoryState> emit,
  ) async {
    if (state.submitting) return;
    emit(const InventoryState());
    final result = await _read(medicationId);
    if (emit.isDone) return;
    emit(switch (result) {
      AppSuccess(:final value) => InventoryState(
        phase: InventoryPhase.ready,
        inventory: value,
      ),
      AppFailure(code: 'INVENTORY_NOT_FOUND') => const InventoryState(
        phase: InventoryPhase.notInitialized,
      ),
      AppFailure(:final code) => InventoryState(
        phase: InventoryPhase.failure,
        errorCode: code,
      ),
    });
  }

  Future<void> _initial(
    InitialStockSubmitted event,
    Emitter<InventoryState> emit,
  ) => _write(
    emit,
    InventoryPhase.notInitialized,
    () => _registerInitial(
      medicationId,
      quantity: event.quantity,
      threshold: event.threshold,
    ),
    replenished: false,
  );

  Future<void> _replenishment(
    ReplenishmentSubmitted event,
    Emitter<InventoryState> emit,
  ) => _write(
    emit,
    InventoryPhase.ready,
    () => _replenish(medicationId, quantity: event.quantity, lot: event.lot),
    replenished: true,
  );

  Future<void> _write(
    Emitter<InventoryState> emit,
    InventoryPhase expected,
    Future<AppResult<Inventory>> Function() send, {
    required bool replenished,
  }) async {
    if (state.phase != expected || state.submitting) return;
    emit(state.copyWith(submitting: true));
    final result = await send();
    if (emit.isDone) return;
    switch (result) {
      case AppSuccess(:final value):
        emit(
          InventoryState(
            phase: InventoryPhase.ready,
            inventory: value,
            replenished: replenished,
          ),
        );
      case AppFailure(code: 'INVENTORY_ALREADY_EXISTS'):
        // Another device registered it first: show what the server has.
        emit(state.copyWith(submitting: false));
        add(const InventoryRequested());
      case AppFailure(:final code) when _fieldCodes.containsKey(code):
        emit(
          state.copyWith(submitting: false, invalidField: _fieldCodes[code]),
        );
      case AppFailure(:final code):
        emit(state.copyWith(submitting: false, errorCode: code));
    }
  }

  void _changed(InventoryInputChanged event, Emitter<InventoryState> emit) {
    if (state.submitting) return;
    if (state.invalidField == null &&
        state.errorCode == null &&
        !state.replenished) {
      return;
    }
    if (state.phase == InventoryPhase.failure) return;
    emit(state.copyWith());
  }
}
