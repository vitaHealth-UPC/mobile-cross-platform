import '../../../application/readmodels/adherence_period.dart';
import '../../../application/readmodels/adherence_summary.dart';

/// Observable phases of the adherence history.
enum HistoryStatus {
  /// A request for the selected period is in flight.
  loading,

  /// The period has definitive intakes and [HistoryState.summary] is set.
  content,

  /// First load without definitive intakes ("Sin datos suficientes").
  insufficientData,

  /// A period the user selected has no definitive intakes ("Sin resultados").
  noResults,

  /// The load failed; [HistoryState.errorCode] says why.
  failure,
}

/// Selected period with its summary, or the reason there is none.
final class HistoryState {
  const HistoryState({
    this.period = AdherencePeriod.lastMonth,
    this.status = HistoryStatus.loading,
    this.summary,
    this.periodUpdated = false,
    this.errorCode,
  });

  final AdherencePeriod period;
  final HistoryStatus status;

  /// Only set while [status] is [HistoryStatus.content].
  final AdherenceSummary? summary;

  /// True when the content answers a period the user just selected.
  final bool periodUpdated;

  /// Stable failure code, translated by the presentation layer.
  final String? errorCode;

  HistoryState copyWith({
    AdherencePeriod? period,
    HistoryStatus? status,
    AdherenceSummary? summary,
    bool? periodUpdated,
    String? errorCode,
  }) => HistoryState(
    period: period ?? this.period,
    status: status ?? this.status,
    summary: summary,
    periodUpdated: periodUpdated ?? this.periodUpdated,
    errorCode: errorCode,
  );
}
