import '../../../../shared/infrastructure/network/api_client.dart';
import '../../../../shared/infrastructure/network/api_response.dart';

/// REST reads of intake evidence for one adult.
final class IntakeApi {
  const IntakeApi(this._client);
  final ApiClient _client;

  /// 200 with the next pending intake, or 204 when none is pending.
  Future<ApiResponse> next(String olderAdultId, String token) =>
      _client.request(
        'GET',
        'api/v1/older-adults/${Uri.encodeComponent(olderAdultId)}/intakes/next',
        token: token,
      );

  /// Ordered evidence scheduled between the UTC instants [from] and [to].
  Future<ApiResponse> agenda(
    String olderAdultId,
    DateTime from,
    DateTime to,
    String token,
  ) => _client.request(
    'GET',
    'api/v1/older-adults/${Uri.encodeComponent(olderAdultId)}/intakes/agenda',
    token: token,
    queryParameters: {
      'from': from.toUtc().toIso8601String(),
      'to': to.toUtc().toIso8601String(),
    },
  );
}
