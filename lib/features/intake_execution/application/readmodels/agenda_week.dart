/// Monday-to-Sunday week of local calendar days, as in Figma 563:3918.
/// Instants are derived in the device time zone, then sent to the server in UTC.
final class AgendaWeek {
  AgendaWeek._(this.start);

  /// Week that contains the local calendar [day].
  factory AgendaWeek.containing(DateTime day) {
    final date = DateTime(day.year, day.month, day.day);
    return AgendaWeek._(
      DateTime(date.year, date.month, date.day - (date.weekday - 1)),
    );
  }

  /// Local midnight of the Monday that opens the week.
  final DateTime start;

  List<DateTime> get days => [
    for (var offset = 0; offset < 7; offset++)
      DateTime(start.year, start.month, start.day + offset),
  ];

  /// Inclusive UTC start of the week.
  DateTime get from => start.toUtc();

  /// Exclusive UTC end of the week; calendar arithmetic keeps DST days correct.
  DateTime get to => DateTime(start.year, start.month, start.day + 7).toUtc();

  /// The same weekday [weeks] weeks later (negative values go back).
  AgendaWeek shift(int weeks) =>
      AgendaWeek._(DateTime(start.year, start.month, start.day + 7 * weeks));

  bool contains(DateTime day) {
    final date = DateTime(day.year, day.month, day.day);
    return !date.isBefore(start) &&
        date.isBefore(DateTime(start.year, start.month, start.day + 7));
  }

  @override
  bool operator ==(Object other) => other is AgendaWeek && other.start == start;

  @override
  int get hashCode => start.hashCode;
}
