import '../../../../shared/common/result/app_result.dart';
import '../../domain/entities/inventory.dart';
import '../../domain/value_objects/inventory_input.dart';
import '../ports/inventory_repository.dart';

/// Adds received units to an existing stock, with an optional lot (US-43).
final class RegisterReplenishment {
  const RegisterReplenishment(this._repository);
  final InventoryRepository _repository;

  Future<AppResult<Inventory>> call(
    String medicationId, {
    required String quantity,
    String lot = '',
  }) async {
    final units = InventoryInput.quantity(quantity);
    if (units == null) return const AppFailure('INVALID_QUANTITY');
    final note = InventoryInput.lot(lot);
    if (!note.valid) return const AppFailure('INVALID_LOT');
    return _repository.replenish(
      medicationId,
      quantity: units,
      lot: note.value,
    );
  }
}
