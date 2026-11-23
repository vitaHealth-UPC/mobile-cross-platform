import '../../../../shared/infrastructure/network/api_client.dart';
import '../../../../shared/infrastructure/network/api_response.dart';

/// REST operations for password access, current identity and session revocation.
final class SessionApi {
  const SessionApi(this._client);
  final ApiClient _client;

  /// Exchanges Firebase evidence for Tata access; provider tokens are not bearers.
  Future<ApiResponse> signInWithFirebase(String idToken) => _client.request(
    'POST',
    'api/v1/social-sessions',
    body: {'firebaseIdToken': idToken},
  );

  Future<ApiResponse> signIn(String email, String password) => _client.request(
    'POST',
    'api/v1/sessions',
    body: {'email': email, 'password': password},
  );

  Future<ApiResponse> current(String token) =>
      _client.request('GET', 'api/v1/sessions/current', token: token);

  Future<ApiResponse> signOut(String token) =>
      _client.request('DELETE', 'api/v1/sessions', token: token);
}
