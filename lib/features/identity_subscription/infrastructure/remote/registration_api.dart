import '../../../../shared/infrastructure/network/api_client.dart';
import '../../../../shared/infrastructure/network/api_response.dart';

/// Anonymous account, verification and resend requests using the public REST contract.
final class RegistrationApi {
  const RegistrationApi(this._client);
  final ApiClient _client;

  Future<ApiResponse> register(String name, String email, String password) =>
      _client.request(
        'POST',
        'api/v1/accounts',
        body: {'name': name, 'email': email, 'password': password},
      );

  Future<ApiResponse> verify(String email, String code) => _client.request(
    'POST',
    'api/v1/accounts/verification',
    body: {'email': email, 'code': code},
  );

  Future<ApiResponse> requestVerification(String email) => _client.request(
    'POST',
    'api/v1/email-verification-requests',
    body: {'email': email},
  );
}
