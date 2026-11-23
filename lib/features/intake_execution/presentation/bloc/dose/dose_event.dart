/// Intent handled by the dose detail state machine.
sealed class DoseEvent {
  const DoseEvent();
}

/// Loads or retries the stored evidence of the dose.
final class DoseRequested extends DoseEvent {
  const DoseRequested();
}

/// Confirms the dose by touch; ignored while busy or when not pending.
final class DoseConfirmRequested extends DoseEvent {
  const DoseConfirmRequested();
}
