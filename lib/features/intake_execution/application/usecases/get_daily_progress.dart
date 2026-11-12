import '../../../../shared/application/time/clock.dart';
import '../../../../shared/common/result/app_result.dart';
import '../ports/intake_reader.dart';
import '../readmodels/daily_progress.dart';

/// Counts today's taken intakes using the device's local calendar day.
/// A dose confirmed offline counts: the adult already took it.
final class GetDailyProgress {
  const GetDailyProgress(this._reader, this._clock);
  final IntakeReader _reader;

  /// Must return local time: the day boundary follows the adult's time zone.
  final Clock _clock;

  Future<AppResult<DailyProgress>> call() async {
    final now = _clock();
    final from = DateTime(now.year, now.month, now.day).toUtc();
    final to = DateTime(now.year, now.month, now.day + 1).toUtc();
    switch (await _reader.agenda(from, to)) {
      case AppFailure(:final code):
        return AppFailure(code);
      case AppSuccess(:final value):
        // Keep one entry per intake and only those inside the requested day.
        final today = {
          for (final intake in value)
            if (!intake.scheduledAt.isBefore(from) &&
                intake.scheduledAt.isBefore(to))
              intake.id: intake,
        }.values;
        return AppSuccess(
          DailyProgress(
            taken: today
                .where((intake) => intake.taken || intake.queued)
                .length,
            total: today.length,
          ),
        );
    }
  }
}
