/// Intent handled by the weekly agenda state machine.
sealed class AgendaEvent {
  const AgendaEvent();
}

/// Loads or refreshes the selected week, for example after a confirmation.
final class AgendaRequested extends AgendaEvent {
  const AgendaRequested();
}

/// Selects a local day inside the current week without a new request.
final class AgendaDaySelected extends AgendaEvent {
  const AgendaDaySelected(this.day);
  final DateTime day;
}

/// Moves [weeks] weeks forward (negative values go back) and reloads.
final class AgendaWeekMoved extends AgendaEvent {
  const AgendaWeekMoved(this.weeks);
  final int weeks;
}
