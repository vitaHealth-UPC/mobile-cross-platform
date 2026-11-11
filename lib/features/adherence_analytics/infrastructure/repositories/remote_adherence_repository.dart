import '../../../../shared/application/session/session_store.dart';
import '../../../../shared/common/result/app_result.dart';
import '../../../../shared/infrastructure/network/api_response.dart';
import '../../application/ports/adherence_reader.dart';
import '../../application/ports/recommendations_reader.dart';
import '../../application/readmodels/adherence_recommendation.dart';
import '../../application/readmodels/adherence_summary.dart';
import '../mappers/adherence_mapper.dart';
import '../remote/analytics_api.dart';
import 'analytics_session_request.dart';

/// Reads adherence views from the Tata REST API for the captured session.
///
/// Both readers distinguish a legitimate empty result (204, returned as a null
/// success) from failures, and never substitute a figure the server did not send.
final class RemoteAdherenceRepository
    implements AdherenceReader, RecommendationsReader {
  const RemoteAdherenceRepository({
    required this._api,
    required this._store,
    required this._zoneId,
  });

  final AnalyticsApi _api;
  final SessionStore _store;

  /// IANA calendar zone sent with every request, for example `America/Lima`.
  final String _zoneId;

  @override
  Future<AppResult<AdherenceSummary?>> summary(
    String olderAdultId,
    int periodDays,
  ) => analyticsSessionRequest(
    _store,
    olderAdultId,
    (session) =>
        _api.summary(olderAdultId, periodDays, _zoneId, session.accessToken),
    (response) => _read(
      response,
      (body) => AdherenceMapper.summary(body, periodDays: periodDays),
    ),
  );

  @override
  Future<AppResult<AdherenceInsight?>> insight(
    String olderAdultId,
    int periodDays,
  ) => analyticsSessionRequest(
    _store,
    olderAdultId,
    (session) =>
        _api.insight(olderAdultId, periodDays, _zoneId, session.accessToken),
    (response) => _read(
      response,
      (body) => AdherenceMapper.insight(body, periodDays: periodDays),
    ),
  );

  AppResult<T?> _read<T>(ApiResponse response, T Function(Object?) map) {
    switch (response.status) {
      case 204:
        return const AppSuccess(null);
      case 200:
        return AppSuccess(map(response.body));
      case 400:
        return const AppFailure('INVALID_REQUEST');
      default:
        return const AppFailure('REQUEST_FAILED');
    }
  }
}
