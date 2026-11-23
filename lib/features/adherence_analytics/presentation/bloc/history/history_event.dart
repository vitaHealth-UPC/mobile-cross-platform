import '../../../application/readmodels/adherence_period.dart';

/// Intent handled by the adherence history state machine.
sealed class HistoryEvent {
  const HistoryEvent();
}

/// Loads or reloads the selected period, for example after a failure.
final class HistoryRequested extends HistoryEvent {
  const HistoryRequested();
}

/// Selects another rolling [period] and loads it; the same period is ignored.
final class HistoryPeriodSelected extends HistoryEvent {
  const HistoryPeriodSelected(this.period);

  final AdherencePeriod period;
}
