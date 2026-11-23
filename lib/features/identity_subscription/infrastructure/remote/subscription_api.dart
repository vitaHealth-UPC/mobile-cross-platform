import '../../../../shared/infrastructure/network/api_client.dart';
import '../../../../shared/infrastructure/network/api_response.dart';

/// REST requests for the plan catalog and an account's subscription.
final class SubscriptionApi {
  const SubscriptionApi(this._client);
  final ApiClient _client;

  Future<ApiResponse> plans(String token) =>
      _client.request('GET', 'api/v1/plans', token: token);

  Future<ApiResponse> current(String accountId, String token) =>
      _client.request(
        'GET',
        'api/v1/accounts/${Uri.encodeComponent(accountId)}/subscription',
        token: token,
      );

  Future<ApiResponse> change(String accountId, String planCode, String token) =>
      _client.request(
        'PUT',
        'api/v1/accounts/${Uri.encodeComponent(accountId)}/subscription',
        token: token,
        body: {'planCode': planCode},
      );
}
