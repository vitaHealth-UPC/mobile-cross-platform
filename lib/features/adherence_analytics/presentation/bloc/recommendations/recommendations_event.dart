/// Intent handled by the recommendations state machine.
sealed class RecommendationsEvent {
  const RecommendationsEvent();
}

/// Loads or reloads the insight, for example after a failure.
final class RecommendationsRequested extends RecommendationsEvent {
  const RecommendationsRequested();
}
