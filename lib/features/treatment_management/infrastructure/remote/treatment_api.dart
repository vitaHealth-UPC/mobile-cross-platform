import '../../../../shared/infrastructure/network/api_client.dart';
import '../../../../shared/infrastructure/network/api_response.dart';

/// Medication and treatment REST requests; every call carries its captured bearer.
final class TreatmentApi {
  const TreatmentApi(this._client);
  final ApiClient _client;

  static String _id(String value) => Uri.encodeComponent(value);

  /// Catalog of the signed-in older adult.
  Future<ApiResponse> myMedications(String token) =>
      _client.request('GET', 'api/v1/me/medications', token: token);

  Future<ApiResponse> registerMedication(
    String olderAdultId,
    String caregiverId,
    String name,
    String presentation,
    String token,
  ) => _client.request(
    'POST',
    'api/v1/older-adults/${_id(olderAdultId)}/medications',
    token: token,
    body: {
      'caregiverId': caregiverId,
      'name': name,
      'presentation': presentation,
    },
  );

  Future<ApiResponse> listMedications(
    String olderAdultId,
    String caregiverId,
    String token,
  ) => _client.request(
    'GET',
    'api/v1/older-adults/${_id(olderAdultId)}/medications',
    token: token,
    queryParameters: {'caregiverId': caregiverId},
  );

  Future<ApiResponse> updateMedication(
    String medicationId,
    String caregiverId,
    String name,
    String presentation,
    String token,
  ) => _client.request(
    'PUT',
    'api/v1/medications/${_id(medicationId)}',
    token: token,
    body: {
      'caregiverId': caregiverId,
      'name': name,
      'presentation': presentation,
    },
  );

  Future<ApiResponse> deactivateMedication(
    String medicationId,
    String caregiverId,
    String token,
  ) => _client.request(
    'POST',
    'api/v1/medications/${_id(medicationId)}/deactivation',
    token: token,
    queryParameters: {'caregiverId': caregiverId},
  );

  Future<ApiResponse> reactivateMedication(
    String medicationId,
    String caregiverId,
    String token,
  ) => _client.request(
    'POST',
    'api/v1/medications/${_id(medicationId)}/reactivation',
    token: token,
    queryParameters: {'caregiverId': caregiverId},
  );

  Future<ApiResponse> createTreatment(
    String olderAdultId,
    String caregiverId,
    String name,
    String token,
  ) => _client.request(
    'POST',
    'api/v1/older-adults/${_id(olderAdultId)}/treatments',
    token: token,
    body: {'caregiverId': caregiverId, 'name': name},
  );

  Future<ApiResponse> listTreatments(
    String olderAdultId,
    String caregiverId,
    String token,
  ) => _client.request(
    'GET',
    'api/v1/older-adults/${_id(olderAdultId)}/treatments',
    token: token,
    queryParameters: {'caregiverId': caregiverId},
  );

  Future<ApiResponse> configureTreatment(
    String treatmentId,
    Map<String, Object?> body,
    String token,
  ) => _client.request(
    'PUT',
    'api/v1/treatments/${_id(treatmentId)}/regimen',
    token: token,
    body: body,
  );

  Future<ApiResponse> activateTreatment(
    String treatmentId,
    String caregiverId,
    String token,
  ) => _transition(treatmentId, 'activation', caregiverId, token);

  Future<ApiResponse> pauseTreatment(
    String treatmentId,
    String caregiverId,
    String token,
  ) => _transition(treatmentId, 'pause', caregiverId, token);

  Future<ApiResponse> resumeTreatment(
    String treatmentId,
    String caregiverId,
    String token,
  ) => _transition(treatmentId, 'resume', caregiverId, token);

  Future<ApiResponse> treatmentDetail(
    String treatmentId,
    String caregiverId,
    String token,
  ) => _client.request(
    'GET',
    'api/v1/treatments/${_id(treatmentId)}',
    token: token,
    queryParameters: {'caregiverId': caregiverId},
  );

  Future<ApiResponse> _transition(
    String treatmentId,
    String action,
    String caregiverId,
    String token,
  ) => _client.request(
    'POST',
    'api/v1/treatments/${_id(treatmentId)}/$action',
    token: token,
    queryParameters: {'caregiverId': caregiverId},
  );
}
