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

  /// Edits basic fields; the actor is taken from the bearer, never the body.
  Future<ApiResponse> updateProfile(
    String olderAdultId,
    String fullName,
    DateTime birthDate,
    String token,
  ) => _client.request(
    'PUT',
    'api/v1/older-adults/${Uri.encodeComponent(olderAdultId)}',
    token: token,
    body: {
      'fullName': fullName,
      'birthDate':
          '${birthDate.year.toString().padLeft(4, '0')}-${birthDate.month.toString().padLeft(2, '0')}-${birthDate.day.toString().padLeft(2, '0')}',
    },
  );

  /// Ends the caregiver's own relationship.
  Future<ApiResponse> end(String id, String caregiverId, String token) =>
      _client.request(
        'DELETE',
        'api/v1/care-links/${Uri.encodeComponent(id)}',
        token: token,
        queryParameters: {'caregiverId': caregiverId},
      );

  /// New single-use sign-in code for the adult of a confirmed relationship.
  Future<ApiResponse> issueAccessCode(
    String id,
    String caregiverId,
    String token,
  ) => _client.request(
    'POST',
    'api/v1/care-links/${Uri.encodeComponent(id)}/access-codes',
    token: token,
    body: {'caregiverId': caregiverId},
  );

  /// Code another caregiver uses to request caring for the same adult.
  Future<ApiResponse> inviteCaregiver(
    String id,
    String caregiverId,
    String token,
  ) => _client.request(
    'POST',
    'api/v1/care-links/${Uri.encodeComponent(id)}/caregiver-invitations',
    token: token,
    body: {'caregiverId': caregiverId},
  );

  /// Joins an adult with another caregiver's code; the adult must accept.
  Future<ApiResponse> joinAsCaregiver(
    String caregiverId,
    String code,
    String token,
  ) => _client.request(
    'POST',
    'api/v1/care-links/caregiver-joins',
    token: token,
    body: {'caregiverId': caregiverId, 'code': code},
  );

  /// Caregivers waiting for the signed-in adult's decision.
  Future<ApiResponse> caregiverRequests(String token) => _client.request(
    'GET',
    'api/v1/care-links/caregiver-requests',
    token: token,
  );

  Future<ApiResponse> decideCaregiverRequest(
    String id,
    bool accepted,
    String token,
  ) => _client.request(
    'POST',
    'api/v1/care-links/caregiver-requests/${Uri.encodeComponent(id)}/decision',
    token: token,
    body: {'accepted': accepted},
  );

  /// Removes the signed-in adult's account.
  Future<ApiResponse> removeAdultAccount(String token) => _client.request(
    'DELETE',
    'api/v1/care-links/adult-account',
    token: token,
  );

  /// Anonymous: the code itself identifies the adult on a new device.
  Future<ApiResponse> redeemAccessCode(String code) => _client.request(
    'POST',
    'api/v1/care-links/access-code-redemptions',
    body: {'code': code},
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
