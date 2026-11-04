import '../../../../shared/common/result/app_result.dart';
import '../../domain/entities/intake.dart';
import '../ports/intake_reader.dart';
import '../readmodels/agenda_week.dart';

/// Reads one local week of intakes, ordered by schedule and without duplicates.
final class GetWeekAgenda {
  const GetWeekAgenda(this._reader);
  final IntakeReader _reader;

  Future<AppResult<List<Intake>>> call(AgendaWeek week) async {
    switch (await _reader.agenda(week.from, week.to)) {
      case AppFailure(:final code):
        return AppFailure(code);
      case AppSuccess(:final value):
        final unique =
            {
                for (final intake in value)
                  if (!intake.scheduledAt.isBefore(week.from) &&
                      intake.scheduledAt.isBefore(week.to))
                    intake.id: intake,
              }.values.toList()
              ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
        return AppSuccess(unique);
    }
  }
}
