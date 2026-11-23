import '../../../../shared/common/result/app_result.dart';
import '../../domain/entities/inventory.dart';

/// Stock of one medication on the server.
///
/// A medication without stock yet fails with `INVENTORY_NOT_FOUND`, which the
/// screen turns into the initial stock form instead of an error.
abstract interface class InventoryRepository {
  Future<AppResult<Inventory>> find(String medicationId);

  Future<AppResult<Inventory>> registerInitial(
    String medicationId, {
    required int quantity,
    required int threshold,
  });

  Future<AppResult<Inventory>> replenish(
    String medicationId, {
    required int quantity,
    String? lot,
  });
}
