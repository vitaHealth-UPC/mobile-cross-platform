import '../../../../shared/application/session/session_owner.dart';
import '../../../../shared/application/session/session_store.dart';
import '../../../../shared/application/session/stored_session.dart';
import '../../../../shared/common/result/app_result.dart';
import '../../../../shared/infrastructure/network/api_response.dart';
import '../../../../shared/infrastructure/session/authorized_request.dart';
import '../../application/ports/inventory_repository.dart';
import '../../domain/entities/inventory.dart';
import '../mappers/inventory_mapper.dart';
import '../remote/inventory_api.dart';

/// Caregiver access to a medication's stock. Every receipt must name the
/// requested medication; a write must also show the values that were sent.
final class RemoteInventoryRepository implements InventoryRepository {
  const RemoteInventoryRepository({required this._api, required this._store});
  final InventoryApi _api;
  final SessionStore _store;

  /// Codes the server documents for this context; others become generic.
  static const _known = {
    'INVENTORY_NOT_FOUND',
    'MEDICATION_NOT_FOUND',
    'MEDICATION_INACTIVE',
    'INVENTORY_ALREADY_EXISTS',
    'CONCURRENT_UPDATE',
    'INVALID_QUANTITY',
  };

  @override
  Future<AppResult<Inventory>> find(String medicationId) => _request(
    medicationId,
    (session) => _api.find(medicationId, session.accessToken),
    success: 200,
    (_) => true,
  );

  @override
  Future<AppResult<Inventory>> registerInitial(
    String medicationId, {
    required int quantity,
    required int threshold,
  }) => _request(
    medicationId,
    (session) => _api.registerInitial(
      medicationId,
      quantity,
      threshold,
      session.accessToken,
    ),
    success: 201,
    (inventory) =>
        inventory.replenishmentThreshold == threshold &&
        inventory.batches.any((batch) => batch.quantity == quantity),
  );

  @override
  Future<AppResult<Inventory>> replenish(
    String medicationId, {
    required int quantity,
    String? lot,
  }) => _request(
    medicationId,
    (session) =>
        _api.replenish(medicationId, quantity, lot, session.accessToken),
    success: 201,
    (inventory) =>
        inventory.batches.length > 1 &&
        inventory.batches.any(
          (batch) => batch.quantity == quantity && batch.lot == lot,
        ),
  );

  Future<AppResult<Inventory>> _request(
    String medicationId,
    Future<ApiResponse> Function(StoredSession session) request,
    bool Function(Inventory inventory) acknowledges, {
    required int success,
  }) => authorizedRequest(_store, const {SessionRole.caregiver}, request, (
    response,
    _,
  ) {
    if (response.status == success) {
      final inventory = InventoryMapper.inventory(response.body);
      return inventory.medicationId == medicationId && acknowledges(inventory)
          ? AppSuccess(inventory)
          : const AppFailure('INVALID_RESPONSE');
    }
    final code = InventoryMapper.errorCode(response.body);
    if (code != null && _known.contains(code)) return AppFailure(code);
    return AppFailure(switch (response.status) {
      400 => 'VALIDATION_ERROR',
      404 => 'INVENTORY_NOT_FOUND',
      409 => 'CONCURRENT_UPDATE',
      _ => 'REQUEST_FAILED',
    });
  });
}
