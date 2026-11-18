import '../../domain/entities/intake.dart';

/// Intakes taken over intakes scheduled for one local calendar day.
final class DailyProgress {
  const DailyProgress({required this.taken, required this.total, this.due})
    : assert(taken >= 0 && taken <= total);

  final int taken;
  final int total;

  /// Earliest dose of the day whose time has come and that is still pending on
  /// the server and on this device (Figma 563:2619 and 563:3682).
  final Intake? due;

  /// Ratio in [0, 1]; an empty day has no progress rather than full progress.
  double get ratio => total == 0 ? 0 : taken / total;
}
