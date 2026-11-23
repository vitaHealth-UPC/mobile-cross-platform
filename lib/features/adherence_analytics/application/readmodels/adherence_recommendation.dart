import 'adherence_summary.dart';

/// Kind of recurring difficulty identified by the server.
enum AdherencePatternType {
  /// Omissions are at least as many as late intakes in the band.
  omission,

  /// Late intakes outnumber omissions in the band.
  lateness,
}

/// Follow-up actions the server may recommend. They only concern reminders,
/// schedules and caregiver follow-up, never a dose or a medical indication.
enum AdherenceRecommendation {
  /// Warn before the scheduled time.
  adjustReminder,

  /// Move the intake to a steadier routine.
  reviewSchedule,

  /// Check the new schedule for one week.
  followUpOneWeek,
}

/// Facts of a recurring pattern, without display text.
final class AdherenceInsightPattern {
  const AdherenceInsightPattern({
    required this.type,
    required this.timeBand,
    required this.omittedCount,
    required this.lateCount,
    required this.fromHour,
    required this.toHour,
  });

  final AdherencePatternType type;
  final AdherenceTimeBand timeBand;
  final int omittedCount;
  final int lateCount;

  /// Local start hour, inclusive.
  final int fromHour;

  /// Local end hour, exclusive; an end at or before the start belongs to the
  /// following day and 24 denotes midnight.
  final int toHour;
}

/// Server insight: the pattern, its weekly concentration and the actions.
///
/// Absence of conclusive evidence is not an [AdherenceInsight]: the reader
/// returns a null success instead, and no clinical criterion is built locally.
final class AdherenceInsight {
  const AdherenceInsight({
    required this.periodDays,
    required this.pattern,
    required this.concentration,
    required this.recommendations,
  });

  final int periodDays;
  final AdherenceInsightPattern pattern;

  /// Three rows (morning, afternoon, evening and night) by seven columns
  /// (Monday to Sunday); each cell is an intensity between 0 and 1.
  final List<List<double>> concentration;

  /// Known actions only; codes this client does not recognize are dropped.
  final List<AdherenceRecommendation> recommendations;
}
