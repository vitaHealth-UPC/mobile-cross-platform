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

  /// 200 with stored evidence, or 404 for an unknown intake.
  Future<ApiResponse> detail(String intakeId, String token) => _client.request(
    'GET',
    'api/v1/intakes/${Uri.encodeComponent(intakeId)}',
    token: token,
  );

  /// Manual confirmation; the backend accepts only the TOUCH channel here.
  /// [confirmedAt] reports an offline action; omit it to use server time.
  Future<ApiResponse> confirm(
    String intakeId,
    String token, {
    DateTime? confirmedAt,
  }) => _client.request(
    'POST',
    'api/v1/intakes/${Uri.encodeComponent(intakeId)}/confirmation',
    token: token,
    body: {
      'channel': 'TOUCH',
      'confirmedAt': ?confirmedAt?.toUtc().toIso8601String(),
    },
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
