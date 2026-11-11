import '../../../application/readmodels/adherence_summary.dart';

/// Days of evidence the adherence level considers: the last month.
const adherenceLevelPeriodDays = 30;

/// Observable phases of the adherence level.
enum LevelStatus {
  /// A request is in flight.
  loading,

  /// The period has definitive intakes and [LevelState.summary] is set.
  content,

  /// The period has no definitive intakes to rate.
  insufficientData,

  /// The load failed; [LevelState.errorCode] says why.
  failure,
}

/// Adherence of the last month, or the reason there is none.
final class LevelState {
  const LevelState({
    this.status = LevelStatus.loading,
    this.summary,
    this.errorCode,
  });

  final LevelStatus status;

  /// Only set while [status] is [LevelStatus.content].
  final AdherenceSummary? summary;

  /// Stable failure code, translated by the presentation layer.
  final String? errorCode;
}
