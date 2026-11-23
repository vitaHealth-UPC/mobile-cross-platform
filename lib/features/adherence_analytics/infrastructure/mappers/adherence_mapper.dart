import '../../application/readmodels/adherence_recommendation.dart';
import '../../application/readmodels/adherence_summary.dart';
import '../../application/readmodels/adherence_trend_point.dart';
import '../remote/adherence_dto.dart';

/// Converts untrusted adherence JSON into read models.
///
/// Throws [FormatException] when a figure is out of range, an enum code is
/// unknown, a timestamp lacks an offset or the response does not describe the
/// requested period.
abstract final class AdherenceMapper {
  /// Maps `GET .../adherence/summary` for the requested [periodDays].
  static AdherenceSummary summary(Object? body, {required int periodDays}) {
    final dto = SummaryDto.fromJson(body);
    if (dto.periodDays != periodDays) throw const FormatException();
    _percent(dto.adherencePercent);
    _percent(dto.onTimePercent);
    _count(dto.scheduledCount);
    _count(dto.lateCount);
    _count(dto.omittedCount);
    return AdherenceSummary(
      periodDays: dto.periodDays,
      scheduledCount: dto.scheduledCount,
      adherencePercent: dto.adherencePercent,
      adherenceChangePercent: dto.adherenceChangePercent,
      onTimePercent: dto.onTimePercent,
      onTimeChangePercent: dto.onTimeChangePercent,
      lateCount: dto.lateCount,
      omittedCount: dto.omittedCount,
      trend: [for (final point in dto.trend) _trendPoint(point)],
      recentIntakes: [for (final item in dto.recentIntakes) _recent(item)],
      pattern: dto.pattern == null
          ? null
          : DetectedPattern(
              timeBand: _timeBand(dto.pattern!.timeBand),
              omittedCount: _count(dto.pattern!.omittedCount),
              lateCount: _count(dto.pattern!.lateCount),
            ),
    );
  }

  /// Maps `GET .../adherence/insight` for the requested [periodDays].
  ///
  /// Recommendation codes this client does not know are dropped so a newer
  /// server can add actions without breaking an older app.
  static AdherenceInsight insight(Object? body, {required int periodDays}) {
    final dto = InsightDto.fromJson(body);
    if (dto.periodDays != periodDays) throw const FormatException();
    final pattern = dto.pattern;
    if (pattern.fromHour < 0 ||
        pattern.fromHour > 23 ||
        pattern.toHour < 0 ||
        pattern.toHour > 24) {
      throw const FormatException();
    }
    if (dto.concentration.length != 3 ||
        dto.concentration.any(
          (row) => row.length != 7 || row.any((v) => v < 0 || v > 1),
        )) {
      throw const FormatException();
    }
    return AdherenceInsight(
      periodDays: dto.periodDays,
      pattern: AdherenceInsightPattern(
        type: switch (pattern.type) {
          'OMISSION' => AdherencePatternType.omission,
          'LATENESS' => AdherencePatternType.lateness,
          _ => throw const FormatException(),
        },
        timeBand: _timeBand(pattern.timeBand),
        omittedCount: _count(pattern.omittedCount),
        lateCount: _count(pattern.lateCount),
        fromHour: pattern.fromHour,
        toHour: pattern.toHour,
      ),
      concentration: dto.concentration,
      recommendations: [
        for (final code in dto.recommendations)
          ?switch (code) {
            'ADJUST_REMINDER' => AdherenceRecommendation.adjustReminder,
            'REVIEW_SCHEDULE' => AdherenceRecommendation.reviewSchedule,
            'FOLLOW_UP_ONE_WEEK' => AdherenceRecommendation.followUpOneWeek,
            _ => null,
          },
      ],
    );
  }

  static AdherenceTrendPoint _trendPoint(TrendPointDto dto) {
    final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(dto.date);
    if (match == null) throw const FormatException();
    final year = int.parse(match[1]!);
    final month = int.parse(match[2]!);
    final day = int.parse(match[3]!);
    final date = DateTime(year, month, day);
    // DateTime rolls over invalid days such as 2026-02-31 instead of failing.
    if (date.year != year || date.month != month || date.day != day) {
      throw const FormatException();
    }
    return AdherenceTrendPoint(
      date: date,
      adherencePercent: _percent(dto.adherencePercent),
    );
  }

  static RecentIntake _recent(RecentIntakeDto dto) {
    final outcome = switch (dto.status) {
      'CONFIRMED' => IntakeOutcome.onTime,
      'LATE' => IntakeOutcome.late,
      'OMITTED' => IntakeOutcome.omitted,
      _ => throw const FormatException(),
    };
    final minutes = dto.minutesLate;
    if (minutes != null && (outcome != IntakeOutcome.late || minutes < 0)) {
      throw const FormatException();
    }
    return RecentIntake(
      scheduledAt: _instant(dto.scheduledAt).toLocal(),
      medicationName: dto.medicationName,
      outcome: outcome,
      minutesLate: minutes,
    );
  }

  static AdherenceTimeBand _timeBand(String code) => switch (code) {
    'MORNING' => AdherenceTimeBand.morning,
    'AFTERNOON' => AdherenceTimeBand.afternoon,
    'EVENING' => AdherenceTimeBand.evening,
    'NIGHT' => AdherenceTimeBand.night,
    _ => throw const FormatException(),
  };

  static int _percent(int value) {
    if (value < 0 || value > 100) throw const FormatException();
    return value;
  }

  static int _count(int value) {
    if (value < 0) throw const FormatException();
    return value;
  }

  // An offset is required: a local timestamp would shift the intake time.
  static DateTime _instant(String value) {
    if (!RegExp(r'(Z|[+-]\d{2}:\d{2})$').hasMatch(value)) {
      throw const FormatException();
    }
    return DateTime.parse(value).toUtc();
  }
}
