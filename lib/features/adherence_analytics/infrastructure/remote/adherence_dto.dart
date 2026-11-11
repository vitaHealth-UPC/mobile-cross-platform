/// Transport shape of one trend point of the summary.
final class TrendPointDto {
  const TrendPointDto({required this.date, required this.adherencePercent});

  factory TrendPointDto.fromJson(Object? json) {
    final map = _object(json);
    return TrendPointDto(
      date: _string(map, 'date'),
      adherencePercent: _int(map, 'adherencePercent'),
    );
  }

  final String date;
  final int adherencePercent;
}

/// Transport shape of one recent intake of the summary.
final class RecentIntakeDto {
  const RecentIntakeDto({
    required this.scheduledAt,
    required this.medicationName,
    required this.status,
    this.minutesLate,
  });

  factory RecentIntakeDto.fromJson(Object? json) {
    final map = _object(json);
    return RecentIntakeDto(
      scheduledAt: _string(map, 'scheduledAt'),
      medicationName: _string(map, 'medicationName'),
      status: _string(map, 'status'),
      minutesLate: _optionalInt(map, 'minutesLate'),
    );
  }

  final String scheduledAt;
  final String medicationName;
  final String status;
  final int? minutesLate;
}

/// Transport shape of the pattern embedded in the summary.
final class SummaryPatternDto {
  const SummaryPatternDto({
    required this.timeBand,
    required this.omittedCount,
    required this.lateCount,
  });

  factory SummaryPatternDto.fromJson(Object? json) {
    final map = _object(json);
    return SummaryPatternDto(
      timeBand: _string(map, 'timeBand'),
      omittedCount: _int(map, 'omittedCount'),
      lateCount: _int(map, 'lateCount'),
    );
  }

  final String timeBand;
  final int omittedCount;
  final int lateCount;
}

/// Transport shape of `GET .../adherence/summary`.
///
/// A missing field, a wrong JSON type or a null where a value is required
/// throws [FormatException]; a legitimately absent value stays null, so the
/// mapper can tell "no evidence" from a broken response.
final class SummaryDto {
  const SummaryDto({
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

  factory SummaryDto.fromJson(Object? json) {
    final map = _object(json);
    return SummaryDto(
      periodDays: _int(map, 'periodDays'),
      scheduledCount: _int(map, 'scheduledCount'),
      adherencePercent: _int(map, 'adherencePercent'),
      adherenceChangePercent: _optionalInt(map, 'adherenceChangePercent'),
      onTimePercent: _int(map, 'onTimePercent'),
      onTimeChangePercent: _optionalInt(map, 'onTimeChangePercent'),
      lateCount: _int(map, 'lateCount'),
      omittedCount: _int(map, 'omittedCount'),
      trend: [
        for (final item in _optionalList(map, 'trend'))
          TrendPointDto.fromJson(item),
      ],
      recentIntakes: [
        for (final item in _optionalList(map, 'recentIntakes'))
          RecentIntakeDto.fromJson(item),
      ],
      pattern: map['pattern'] == null
          ? null
          : SummaryPatternDto.fromJson(map['pattern']),
    );
  }

  final int periodDays;
  final int scheduledCount;
  final int adherencePercent;
  final int? adherenceChangePercent;
  final int onTimePercent;
  final int? onTimeChangePercent;
  final int lateCount;
  final int omittedCount;
  final List<TrendPointDto> trend;
  final List<RecentIntakeDto> recentIntakes;
  final SummaryPatternDto? pattern;
}

/// Transport shape of the pattern of `GET .../adherence/insight`.
final class InsightPatternDto {
  const InsightPatternDto({
    required this.type,
    required this.timeBand,
    required this.omittedCount,
    required this.lateCount,
    required this.fromHour,
    required this.toHour,
  });

  factory InsightPatternDto.fromJson(Object? json) {
    final map = _object(json);
    return InsightPatternDto(
      type: _string(map, 'type'),
      timeBand: _string(map, 'timeBand'),
      omittedCount: _int(map, 'omittedCount'),
      lateCount: _int(map, 'lateCount'),
      fromHour: _int(map, 'fromHour'),
      toHour: _int(map, 'toHour'),
    );
  }

  final String type;
  final String timeBand;
  final int omittedCount;
  final int lateCount;
  final int fromHour;
  final int toHour;
}

/// Transport shape of `GET .../adherence/insight`.
final class InsightDto {
  const InsightDto({
    required this.periodDays,
    required this.pattern,
    required this.concentration,
    required this.recommendations,
  });

  factory InsightDto.fromJson(Object? json) {
    final map = _object(json);
    final rows = map['concentration'];
    final codes = map['recommendations'];
    if (rows is! List<Object?> || codes is! List<Object?>) {
      throw const FormatException();
    }
    return InsightDto(
      periodDays: _int(map, 'periodDays'),
      pattern: InsightPatternDto.fromJson(map['pattern']),
      concentration: [
        for (final row in rows)
          if (row is List<Object?>)
            [
              for (final cell in row)
                if (cell is num)
                  cell.toDouble()
                else
                  throw const FormatException(),
            ]
          else
            throw const FormatException(),
      ],
      recommendations: [
        for (final code in codes)
          if (code is String) code else throw const FormatException(),
      ],
    );
  }

  final int periodDays;
  final InsightPatternDto pattern;
  final List<List<double>> concentration;
  final List<String> recommendations;
}

Map<String, Object?> _object(Object? json) {
  if (json is! Map<String, Object?>) throw const FormatException();
  return json;
}

String _string(Map<String, Object?> map, String key) {
  final value = map[key];
  if (value is! String || value.trim().isEmpty) throw const FormatException();
  return value;
}

int _int(Map<String, Object?> map, String key) {
  final value = map[key];
  if (value is! int) throw const FormatException();
  return value;
}

int? _optionalInt(Map<String, Object?> map, String key) {
  final value = map[key];
  if (value == null) return null;
  if (value is! int) throw const FormatException();
  return value;
}

List<Object?> _optionalList(Map<String, Object?> map, String key) {
  final value = map[key];
  if (value == null) return const [];
  if (value is! List<Object?>) throw const FormatException();
  return value;
}
