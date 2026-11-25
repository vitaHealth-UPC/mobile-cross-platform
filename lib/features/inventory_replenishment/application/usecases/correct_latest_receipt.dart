import '../../../../shared/common/result/app_result.dart';
import '../../domain/entities/inventory.dart';
import '../../domain/value_objects/inventory_input.dart';
import '../ports/inventory_repository.dart';

/// Fixes a mistyped initial stock or last replenishment, once, before any
/// intake consumes a unit after it. The threshold only travels with the
/// initial stock.
final class CorrectLatestReceipt {
  const CorrectLatestReceipt(this._repository);
  final InventoryRepository _repository;

  Future<AppResult<Inventory>> call(
    String medicationId, {
    required String batchId,
    required String quantity,
    String lot = '',
    String? threshold,
  }) async {
    final units = InventoryInput.quantity(quantity);
    if (units == null) return const AppFailure('INVALID_QUANTITY');
    final note = InventoryInput.lot(lot);
    if (!note.valid) return const AppFailure('INVALID_LOT');
    int? limit;
    if (threshold != null) {
      limit = InventoryInput.threshold(threshold);
      if (limit == null) return const AppFailure('INVALID_THRESHOLD');
    }
    return _repository.correctLatest(
      medicationId,
      batchId: batchId,
      quantity: units,
      lot: note.value,
      threshold: limit,
    );
  }
}
