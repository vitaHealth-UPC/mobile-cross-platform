import '../../../../shared/infrastructure/network/api_client.dart';
import '../../../../shared/infrastructure/network/api_response.dart';

/// REST requests of Family Monitoring; every call carries the bearer captured by its caller.
/// The caregiver id sent as a query value is always the owner of that captured session.
final class FamilyMonitoringApi {
  const FamilyMonitoringApi(this._client);
  final ApiClient _client;

  static String _id(String value) => Uri.encodeComponent(value);
  static String _adult(String olderAdultId) =>
      'api/v1/older-adults/${_id(olderAdultId)}';

  /// Weekly adherence and open alerts.
  Future<ApiResponse> status(
    String olderAdultId,
    String caregiverId,
    String token,
  ) => _client.request(
    'GET',
    '${_adult(olderAdultId)}/status',
    token: token,
    queryParameters: {'caregiverId': caregiverId},
  );

  /// Intakes scheduled between the UTC instants [from] and [to].
  Future<ApiResponse> agenda(
    String olderAdultId,
    DateTime from,
    DateTime to,
    String token,
  ) => _client.request(
    'GET',
    '${_adult(olderAdultId)}/intakes/agenda',
    token: token,
    queryParameters: {
      'from': from.toUtc().toIso8601String(),
      'to': to.toUtc().toIso8601String(),
    },
  );

  /// Next pending intake; the server answers 204 when there is none.
  Future<ApiResponse> nextIntake(String olderAdultId, String token) => _client
      .request('GET', '${_adult(olderAdultId)}/intakes/next', token: token);

  Future<ApiResponse> intake(String intakeId, String token) =>
      _client.request('GET', 'api/v1/intakes/${_id(intakeId)}', token: token);

  Future<ApiResponse> inventory(String medicationId, String token) => _client
      .request('GET', 'api/v1/inventories/${_id(medicationId)}', token: token);

  Future<ApiResponse> contactChannel(
    String olderAdultId,
    String caregiverId,
    String token,
  ) => _client.request(
    'GET',
    '${_adult(olderAdultId)}/contact-channel',
    token: token,
    queryParameters: {'caregiverId': caregiverId},
  );

  Future<ApiResponse> profile(String olderAdultId, String token) =>
      _client.request('GET', _adult(olderAdultId), token: token);

  Future<ApiResponse> history(
    String olderAdultId,
    String caregiverId,
    int days,
    String token,
  ) => _client.request(
    'GET',
    '${_adult(olderAdultId)}/intakes',
    token: token,
    queryParameters: {'caregiverId': caregiverId, 'days': '$days'},
  );

  Future<ApiResponse> alert(
    String olderAdultId,
    int alertId,
    String caregiverId,
    String token,
  ) => _client.request(
    'GET',
    '${_adult(olderAdultId)}/alerts/$alertId',
    token: token,
    queryParameters: {'caregiverId': caregiverId},
  );

  Future<ApiResponse> updateAlertStatus(
    String olderAdultId,
    int alertId,
    String caregiverId,
    String status,
    String token,
  ) => _client.request(
    'PUT',
    '${_adult(olderAdultId)}/alerts/$alertId/status',
    token: token,
    queryParameters: {'caregiverId': caregiverId},
    body: {'status': status},
  );

  Future<ApiResponse> alertTimeline(
    String olderAdultId,
    int alertId,
    String caregiverId,
    String token,
  ) => _client.request(
    'GET',
    '${_adult(olderAdultId)}/alerts/$alertId/timeline',
    token: token,
    queryParameters: {'caregiverId': caregiverId},
  );

  Future<ApiResponse> notes(
    String olderAdultId,
    String caregiverId,
    String token,
  ) => _client.request(
    'GET',
    '${_adult(olderAdultId)}/notes',
    token: token,
    queryParameters: {'caregiverId': caregiverId},
  );

  /// The author goes in the body: there is no `caregiverId` query on POST.
  Future<ApiResponse> registerNote(
    String olderAdultId,
    String caregiverId,
    String text,
    String token,
  ) => _client.request(
    'POST',
    '${_adult(olderAdultId)}/notes',
    token: token,
    body: {'familiarId': caregiverId, 'text': text},
  );

  Future<ApiResponse> personalNotes(String token) =>
      _client.request('GET', 'api/v1/me/notes', token: token);

  Future<ApiResponse> createPersonalNote(
    String title,
    String text,
    String category,
    String token,
  ) => _client.request(
    'POST',
    'api/v1/me/notes',
    token: token,
    body: {'title': title, 'text': text, 'category': category},
  );
}
