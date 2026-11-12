/// Local time of day written as `H:mm` or `HH:mm`; seconds are not supported.
final class ClockTime implements Comparable<ClockTime> {
  const ClockTime._(this.hour, this.minute);

  final int hour;
  final int minute;

  static final _pattern = RegExp(r'^([01]?\d|2[0-3]):([0-5]\d)$');

  static ClockTime? tryParse(String raw) {
    final match = _pattern.firstMatch(raw.trim());
    if (match == null) return null;
    return ClockTime._(int.parse(match.group(1)!), int.parse(match.group(2)!));
  }

  /// Parses the server form, which may carry zero seconds (`08:00:00`).
  static ClockTime? tryParseServer(String raw) {
    final match = RegExp(r'^(\d{2}:\d{2})(:00)?$').firstMatch(raw.trim());
    return match == null ? null : tryParse(match.group(1)!);
  }

  @override
  int compareTo(ClockTime other) =>
      (hour * 60 + minute).compareTo(other.hour * 60 + other.minute);

  @override
  bool operator ==(Object other) =>
      other is ClockTime && hour == other.hour && minute == other.minute;

  @override
  int get hashCode => Object.hash(hour, minute);

  /// Backend and display form, always `HH:mm`.
  @override
  String toString() =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}

/// Nonempty, sorted and distinct local administration times.
final class AdministrationSchedule {
  const AdministrationSchedule._(this.times);

  final List<ClockTime> times;

  static AdministrationSchedule? create(Iterable<ClockTime> times) {
    final normalized = times.toSet().toList()..sort();
    return normalized.isEmpty
        ? null
        : AdministrationSchedule._(List.unmodifiable(normalized));
  }
}
