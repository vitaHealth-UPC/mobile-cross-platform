import 'adherence_trend_point.dart';

/// Definitive outcome of one recorded intake; pending intakes never appear.
enum IntakeOutcome {
  /// Confirmed inside the expected window.
  onTime,

  /// Confirmed after the expected window.
  late,

  /// Never confirmed.
  omitted,
}

/// Local time bands the server uses to group late and omitted intakes.
enum AdherenceTimeBand {
  /// From 05:00 to 12:00.
  morning,

  /// From 12:00 to 18:00.
  afternoon,

  /// From 18:00 to 22:00.
  evening,

  /// The rest of the day.
  night,
}

/// One of the most recent intakes with its outcome, at its local schedule.
final class RecentIntake {
  const RecentIntake({
    required this.scheduledAt,
    required this.medicationName,
    required this.outcome,
    this.minutesLate,
  });

  /// Scheduled instant, already converted to the device time zone.
  final DateTime scheduledAt;

  /// Name registered when the intake was scheduled.
  final String medicationName;
  final IntakeOutcome outcome;

  /// Only present for [IntakeOutcome.late].
  final int? minutesLate;
}

/// Late and omitted intakes that concentrate in one time band.
final class DetectedPattern {
  const DetectedPattern({
    required this.timeBand,
    required this.omittedCount,
    required this.lateCount,
  });

  final AdherenceTimeBand timeBand;
  final int omittedCount;
  final int lateCount;
}

/// Figures, trend and recent outcomes of one adherence period.
///
/// Language-independent: the presentation layer owns every visible text.
final class AdherenceSummary {
  const AdherenceSummary({
    required this.periodDays,
    required this.scheduledCount,
    required this.adherencePercent,
    required this.onTimePercent,
    required this.lateCount,
    required this.omittedCount,
    required this.trend,
    required this.recentIntakes,
    this.adherenceChangePercent,
    this.onTimeChangePercent,
    this.pattern,
  });

  final int periodDays;
  final int scheduledCount;

  /// Confirmed plus late intakes over the definitive ones, from 0 to 100.
  final int adherencePercent;

  /// Difference with the previous period, or null when it had no evidence.
  final int? adherenceChangePercent;

  /// Intakes confirmed on time over the definitive ones, from 0 to 100.
  final int onTimePercent;
  final int? onTimeChangePercent;
  final int lateCount;
  final int omittedCount;
  final List<AdherenceTrendPoint> trend;
  final List<RecentIntake> recentIntakes;

  /// Null unless late or omitted intakes concentrate in one time band.
  final DetectedPattern? pattern;
}
