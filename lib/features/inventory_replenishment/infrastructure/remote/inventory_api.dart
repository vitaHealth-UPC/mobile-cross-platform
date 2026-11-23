import '../../../../shared/infrastructure/network/api_client.dart';
import '../../../../shared/infrastructure/network/api_response.dart';

/// REST requests of the Inventory & Replenishment context.
final class InventoryApi {
  const InventoryApi(this._client);
  final ApiClient _client;

  Future<ApiResponse> find(String medicationId, String token) =>
      _client.request(
        'GET',
        'api/v1/inventories/${Uri.encodeComponent(medicationId)}',
        token: token,
      );

  Future<ApiResponse> registerInitial(
    String medicationId,
    int quantity,
    int threshold,
    String token,
  ) => _client.request(
    'POST',
    'api/v1/inventories',
    token: token,
    body: {
      'medicationId': medicationId,
      'initialQuantity': quantity,
      'replenishmentThreshold': threshold,
    },
  );

  Future<ApiResponse> replenish(
    String medicationId,
    int quantity,
    String? lot,
    String token,
  ) => _client.request(
    'POST',
    'api/v1/inventories/${Uri.encodeComponent(medicationId)}/replenishments',
    token: token,
    body: {'quantity': quantity, 'lot': ?lot},
  );
}
