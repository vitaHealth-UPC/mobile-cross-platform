/// Intent handled by the adherence level state machine.
sealed class LevelEvent {
  const LevelEvent();
}

/// Loads or reloads the level, for example after a failure.
final class LevelRequested extends LevelEvent {
  const LevelRequested();
}
