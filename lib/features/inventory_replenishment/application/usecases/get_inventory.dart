import '../../../../shared/common/result/app_result.dart';
import '../../domain/entities/inventory.dart';
import '../ports/inventory_repository.dart';

/// Reads the stock of a medication (US-41, US-42).
final class GetInventory {
  const GetInventory(this._repository);
  final InventoryRepository _repository;

  Future<AppResult<Inventory>> call(String medicationId) =>
      _repository.find(medicationId);
}
