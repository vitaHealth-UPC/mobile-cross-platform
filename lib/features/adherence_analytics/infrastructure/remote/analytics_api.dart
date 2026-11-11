import '../../../../shared/infrastructure/network/api_client.dart';
import '../../../../shared/infrastructure/network/api_response.dart';

/// REST reads of the adherence views of one older adult.
final class AnalyticsApi {
  const AnalyticsApi(this._client);

  final ApiClient _client;

  /// 200 with the period summary, or 204 when it has no definitive intakes.
  ///
  /// [zone] is the IANA calendar zone used to bucket days and time bands.
  Future<ApiResponse> summary(
    String olderAdultId,
    int days,
    String zone,
    String token,
  ) => _client.request(
    'GET',
    'api/v1/older-adults/${Uri.encodeComponent(olderAdultId)}/adherence/summary',
    token: token,
    queryParameters: {'days': '$days', 'zone': zone},
  );

  /// 200 with the recurring pattern and recommendation codes, or 204 when the
  /// evidence is insufficient for a conclusive recommendation.
  Future<ApiResponse> insight(
    String olderAdultId,
    int days,
    String zone,
    String token,
  ) => _client.request(
    'GET',
    'api/v1/older-adults/${Uri.encodeComponent(olderAdultId)}/adherence/insight',
    token: token,
    queryParameters: {'days': '$days', 'zone': zone},
  );
}
