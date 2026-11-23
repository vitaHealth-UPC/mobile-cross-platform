/// Intent handled by the weekly agenda state machine.
sealed class AgendaEvent {
  const AgendaEvent();
}

/// Loads or refreshes the selected week, for example after a confirmation.
final class AgendaRequested extends AgendaEvent {
  const AgendaRequested();
}

/// Selects a local day, loading its week only when it differs from the current one.
final class AgendaDaySelected extends AgendaEvent {
  const AgendaDaySelected(this.day);
  final DateTime day;
}
