import '../../../../shared/infrastructure/network/api_client.dart';
import '../../../../shared/infrastructure/network/api_response.dart';

/// Anonymous REST requests for recovery; forwards receipts without interpreting state.
final class PasswordRecoveryApi {
  const PasswordRecoveryApi(this._client);
  final ApiClient _client;

  Future<ApiResponse> request(String email) => _client.request(
    'POST',
    'api/v1/password-recovery-requests',
    body: {'email': email},
  );

  Future<ApiResponse> complete(String email, String code, String newPassword) =>
      _client.request(
        'POST',
        'api/v1/password-recoveries',
        body: {'email': email, 'code': code, 'newPassword': newPassword},
      );
}
