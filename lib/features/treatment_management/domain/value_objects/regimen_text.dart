/// Normalized dose description, nonblank and at most 100 characters.
final class Dosage {
  const Dosage._(this.value);
  final String value;

  static Dosage? tryParse(String raw) {
    final normalized = raw.trim();
    return normalized.isNotEmpty && normalized.length <= 100
        ? Dosage._(normalized)
        : null;
  }
}

/// Supported backend recurrence labels. UI labels may be localized, but the API
/// uses the established Spanish/DAILY contract.
enum FrequencyKind {
  daily,
  onceDaily,
  eightHours,
  twelveHours,

  /// Any other whole-hour interval in [Frequency.supportedIntervals].
  interval,
  prescribed,
}

final class Frequency {
  const Frequency._(this.value, this.kind, [this.intervalHours]);
  final String value;
  final FrequencyKind kind;

  /// Hours between doses for interval kinds (8 and 12 included), else null.
  final int? intervalHours;

  /// Whole-hour intervals that repeat at the same local times every day; the
  /// server accepts the same set.
  static const supportedIntervals = [2, 3, 4, 6, 8, 12];

  static final _interval = RegExp(
    r'^(?:cada|every) (\d{1,2}) (?:horas|hours)$',
  );

  static String _normalize(String value) => value
      .toLowerCase()
      .replaceAll('í', 'i')
      .replaceAll('ó', 'o')
      .replaceAll('ú', 'u')
      .replaceAll('é', 'e')
      .replaceAll(RegExp(r'\s+'), ' ');

  static Frequency? tryParse(String raw) {
    final value = raw.trim();
    if (value.length > 100) return null;
    final normalized = _normalize(value);
    final kind = switch (normalized) {
      'daily' || 'cada dia' || 'diaria' || 'every day' => FrequencyKind.daily,
      'una vez al dia' ||
      'cada 24 horas' ||
      'once a day' ||
      'once daily' => FrequencyKind.onceDaily,
      'segun indicacion medica' || 'as prescribed' => FrequencyKind.prescribed,
      _ => null,
    };
    if (kind != null) return Frequency._(value, kind);
    final match = _interval.firstMatch(normalized);
    final hours = match == null ? null : int.parse(match.group(1)!);
    if (hours == null || !supportedIntervals.contains(hours)) return null;
    return Frequency._(value, switch (hours) {
      8 => FrequencyKind.eightHours,
      12 => FrequencyKind.twelveHours,
      _ => FrequencyKind.interval,
    }, hours);
  }

  /// Spanish label the API stores, for example `Cada 6 horas`. Spanish
  /// input is sent exactly as typed; only English labels are translated.
  String get backendValue => switch (_normalize(value)) {
    'every day' => 'Cada día',
    'once a day' || 'once daily' => 'Una vez al día',
    'as prescribed' => 'Según indicación médica',
    final label when label.startsWith('every ') => 'Cada $intervalHours horas',
    _ => value,
  };

  /// Doses per day the schedule must hold, or null when any count is valid.
  int? get expectedCount => switch (kind) {
    FrequencyKind.onceDaily => 1,
    FrequencyKind.daily || FrequencyKind.prescribed => null,
    _ => 24 ~/ intervalHours!,
  };

  /// True when the times are derived from a start time instead of typed one
  /// by one: a fixed interval or a single daily dose.
  bool get derivesTimes => expectedCount != null;

  /// Every dose of the day starting at [start], for example 08:00 every 6
  /// hours gives 08:00, 14:00, 20:00 and 02:00 (sorted for display).
  List<int> minutesFrom(int start) {
    final count = expectedCount ?? 1;
    final step = 1440 ~/ count;
    return [for (var i = 0; i < count; i++) (start + i * step) % 1440]..sort();
  }

  /// Mirrors the server's complete daily-cycle rule, including midnight.
  bool matchesMinutes(Iterable<int> minutes) {
    final sorted = minutes.toSet().toList()..sort();
    if (sorted.isEmpty) return false;
    final count = expectedCount;
    if (count == null) return true;
    if (sorted.length != count) return false;
    if (count == 1) return true;
    final interval = 1440 ~/ count;
    for (var i = 0; i < count; i++) {
      final difference = (sorted[(i + 1) % count] - sorted[i] + 1440) % 1440;
      if (difference != interval) return false;
    }
    return true;
  }
}

/// Optional administration instructions limited to 500 normalized characters.
final class AdministrationInstructions {
  const AdministrationInstructions._(this.value);
  final String value;

  static AdministrationInstructions? tryParse(String raw) {
    final normalized = raw.trim();
    return normalized.length <= 500
        ? AdministrationInstructions._(normalized)
        : null;
  }
}

/// Minutes before a follow-up reminder: nonnegative and limited to one day.
final class ReminderDelayMinutes {
  const ReminderDelayMinutes._(this.value);
  final int value;

  static ReminderDelayMinutes? tryParse(String raw) {
    final minutes = int.tryParse(raw.trim());
    return minutes != null && minutes >= 0 && minutes <= 1440
        ? ReminderDelayMinutes._(minutes)
        : null;
  }
}
