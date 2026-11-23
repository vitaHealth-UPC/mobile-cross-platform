import '../../../../shared/common/result/app_result.dart';
import '../../domain/entities/inventory.dart';
import '../../domain/value_objects/inventory_input.dart';
import '../ports/inventory_repository.dart';

/// Registers the first stock of a medication with its low-stock threshold (US-40).
final class RegisterInitialInventory {
  const RegisterInitialInventory(this._repository);
  final InventoryRepository _repository;

  Future<AppResult<Inventory>> call(
    String medicationId, {
    required String quantity,
    required String threshold,
  }) async {
    final units = InventoryInput.quantity(quantity);
    if (units == null) return const AppFailure('INVALID_QUANTITY');
    final limit = InventoryInput.threshold(threshold);
    if (limit == null) return const AppFailure('INVALID_THRESHOLD');
    return _repository.registerInitial(
      medicationId,
      quantity: units,
      threshold: limit,
    );
  }
}
