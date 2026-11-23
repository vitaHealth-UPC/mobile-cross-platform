import '../../../../shared/common/result/app_result.dart';
import '../ports/recommendations_reader.dart';
import '../readmodels/adherence_recommendation.dart';

/// Loads the server insight without generating any clinical criterion locally.
final class GetRecommendations {
  const GetRecommendations(this._reader);

  final RecommendationsReader _reader;

  /// Fails with `INVALID_OLDER_ADULT_REFERENCE` for a blank adult and with
  /// `INVALID_PERIOD` outside 1 to 31 days, before any request is made.
  Future<AppResult<AdherenceInsight?>> call(
    String olderAdultId,
    int periodDays,
  ) {
    final adult = olderAdultId.trim();
    if (adult.isEmpty) {
      return Future.value(const AppFailure('INVALID_OLDER_ADULT_REFERENCE'));
    }
    if (periodDays < 1 || periodDays > 31) {
      return Future.value(const AppFailure('INVALID_PERIOD'));
    }
    return _reader.insight(adult, periodDays);
  }
}
