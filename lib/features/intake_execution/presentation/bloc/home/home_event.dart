/// Intent handled by the adult home state machine.
sealed class HomeEvent {
  const HomeEvent();
}

/// Loads, retries or refreshes the next intake and today's progress.
final class HomeRequested extends HomeEvent {
  const HomeRequested();
}
