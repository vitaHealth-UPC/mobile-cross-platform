import '../../../../shared/common/result/app_result.dart';
import '../readmodels/adherence_recommendation.dart';

/// Reads server-derived follow-up insights of one older adult.
abstract interface class RecommendationsReader {
  /// Returns the insight of the last [periodDays] days. A null success means
  /// the evidence is insufficient for a conclusive recommendation.
  Future<AppResult<AdherenceInsight?>> insight(
    String olderAdultId,
    int periodDays,
  );
}
