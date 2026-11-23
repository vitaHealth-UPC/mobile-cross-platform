/// Adherence percentage of one local calendar date in the trend series.
final class AdherenceTrendPoint {
  const AdherenceTrendPoint({
    required this.date,
    required this.adherencePercent,
  });

  /// Calendar date at local midnight; the server labels days in its zone.
  final DateTime date;

  /// Share of taken (on time or late) intakes, from 0 to 100.
  final int adherencePercent;
}
