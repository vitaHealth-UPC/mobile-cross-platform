import '../../../application/readmodels/agenda_week.dart';
import '../../../domain/entities/intake.dart';

/// Observable phases of the weekly agenda.
enum AgendaStatus { loading, ready, failure }

/// Selected week and day with the week's intakes, ordered by schedule.
final class AgendaState {
  const AgendaState({
    required this.week,
    required this.selectedDay,
    this.status = AgendaStatus.loading,
    this.intakes = const [],
    this.errorCode,
  });

  final AgendaWeek week;

  /// Local calendar day; always inside [week].
  final DateTime selectedDay;
  final AgendaStatus status;
  final List<Intake> intakes;
  final String? errorCode;

  /// Intakes whose local scheduled day is [selectedDay].
  List<Intake> get selectedIntakes => [
    for (final intake in intakes)
      if (_sameDay(intake.scheduledAt.toLocal(), selectedDay)) intake,
  ];

  AgendaState copyWith({
    AgendaWeek? week,
    DateTime? selectedDay,
    AgendaStatus? status,
    List<Intake>? intakes,
    String? errorCode,
  }) => AgendaState(
    week: week ?? this.week,
    selectedDay: selectedDay ?? this.selectedDay,
    status: status ?? this.status,
    intakes: intakes ?? this.intakes,
    errorCode: errorCode,
  );

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
