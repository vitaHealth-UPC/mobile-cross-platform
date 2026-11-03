import '../../../../shared/infrastructure/network/api_client.dart';
import '../../../../shared/infrastructure/network/api_response.dart';

/// REST operations for adult PIN enrollment and PIN-based access.
final class PinApi {
  const PinApi(this._client);
  final ApiClient _client;

  /// Requires the full adult session that owns [olderAdultId].
  Future<ApiResponse> register(String olderAdultId, String pin, String token) =>
      _client.request(
        'POST',
        'api/v1/pin-credentials',
        body: {'olderAdultId': olderAdultId, 'pin': pin},
        token: token,
      );

  /// Public endpoint; the response carries a credential without relationship scope.
  Future<ApiResponse> signIn(String olderAdultId, String pin) =>
      _client.request(
        'POST',
        'api/v1/pin-sessions',
        body: {'olderAdultId': olderAdultId, 'pin': pin},
      );

  /// Resolves the relationship scope of a freshly issued credential.
  Future<ApiResponse> current(String token) =>
      _client.request('GET', 'api/v1/sessions/current', token: token);
}
