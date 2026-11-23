import '../../../../shared/infrastructure/network/api_client.dart';
import '../../../../shared/infrastructure/network/api_response.dart';

/// Authenticated installation endpoints; ownership is resolved by the backend from the
/// bearer, so no user identifier travels in the request.
final class PushDeviceApi {
  const PushDeviceApi(this._client);
  final ApiClient _client;

  Future<ApiResponse> register(
    String installationId,
    String token,
    String bearer,
  ) => _client.request(
    'PUT',
    'api/v1/push-devices/${Uri.encodeComponent(installationId)}',
    token: bearer,
    body: {'token': token},
  );

  Future<ApiResponse> unregister(String installationId, String bearer) =>
      _client.request(
        'DELETE',
        'api/v1/push-devices/${Uri.encodeComponent(installationId)}',
        token: bearer,
      );
}
