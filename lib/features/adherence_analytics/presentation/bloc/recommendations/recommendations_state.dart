import '../../../application/readmodels/adherence_recommendation.dart';

/// Days of evidence the recommendations screen asks the server to consider.
const recommendationsPeriodDays = 30;

/// Observable phases of the recommendations screen.
enum RecommendationsStatus {
  /// A request is in flight.
  loading,

  /// The server found a recurring pattern and [RecommendationsState.insight]
  /// is set.
  content,

  /// The evidence is not enough for a conclusive recommendation.
  insufficientEvidence,

  /// The load failed; [RecommendationsState.errorCode] says why.
  failure,
}

/// Server insight, or the reason there is none.
final class RecommendationsState {
  const RecommendationsState({
    this.status = RecommendationsStatus.loading,
    this.insight,
    this.errorCode,
  });

  final RecommendationsStatus status;

  /// Only set while [status] is [RecommendationsStatus.content].
  final AdherenceInsight? insight;

  /// Stable failure code, translated by the presentation layer.
  final String? errorCode;
}
