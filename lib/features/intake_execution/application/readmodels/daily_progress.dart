/// Intakes taken over intakes scheduled for one local calendar day.
final class DailyProgress {
  const DailyProgress({required this.taken, required this.total})
    : assert(taken >= 0 && taken <= total);

  final int taken;
  final int total;

  /// Ratio in [0, 1]; an empty day has no progress rather than full progress.
  double get ratio => total == 0 ? 0 : taken / total;
}
