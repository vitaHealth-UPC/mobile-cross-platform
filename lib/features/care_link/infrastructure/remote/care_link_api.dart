import '../../../../shared/infrastructure/network/api_client.dart';
import '../../../../shared/infrastructure/network/api_response.dart';

/// Caregiver setup and authorized relationship REST requests, with captured bearer.
final class CareLinkApi {
  const CareLinkApi(this._client);
  final ApiClient _client;

  /// Uses the adult's captured relationship scope, not a caller-supplied body actor.
  Future<ApiResponse> withdraw(String id, String token) => _client.request(
    'DELETE',
    'api/v1/care-links/${Uri.encodeComponent(id)}/consent',
    token: token,
  );

  /// Anonymous acceptance does not inherit an existing caregiver bearer.
  Future<ApiResponse> accept(String caregiverId, String code) =>
      _client.request(
        'POST',
        'api/v1/care-links/acceptances',
        body: {'caregiverId': caregiverId, 'code': code},
      );

  Future<ApiResponse> link(String id, String token) => _client.request(
    'GET',
    'api/v1/care-links/${Uri.encodeComponent(id)}',
    token: token,
  );

  Future<ApiResponse> consent(String id, bool accepted, String token) =>
      _client.request(
        'POST',
        'api/v1/care-links/${Uri.encodeComponent(id)}/consent',
        token: token,
        body: {'accepted': accepted},
      );

  Future<ApiResponse> confirmed(String caregiverId, String token) =>
      _client.request(
        'GET',
        'api/v1/care-links',
        token: token,
        queryParameters: {'caregiverId': caregiverId},
      );

  Future<ApiResponse> register(
    String caregiverId,
    String name,
    DateTime birthDate,
    String token,
  ) => _client.request(
    'POST',
    'api/v1/older-adults',
    token: token,
    body: {
      'caregiverId': caregiverId,
      'fullName': name,
      'birthDate':
          '${birthDate.year.toString().padLeft(4, '0')}-${birthDate.month.toString().padLeft(2, '0')}-${birthDate.day.toString().padLeft(2, '0')}',
    },
  );

  /// Readable by the adult themself or an authorized caregiver.
  Future<ApiResponse> profile(String olderAdultId, String token) =>
      _client.request(
        'GET',
        'api/v1/older-adults/${Uri.encodeComponent(olderAdultId)}',
        token: token,
      );

  Future<ApiResponse> generate(
    String caregiverId,
    String olderAdultId,
    String token,
  ) => _client.request(
    'POST',
    'api/v1/care-links/linking-codes',
    token: token,
    body: {'caregiverId': caregiverId, 'olderAdultId': olderAdultId},
  );
}
