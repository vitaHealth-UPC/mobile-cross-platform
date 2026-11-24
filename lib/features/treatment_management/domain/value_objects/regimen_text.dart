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
enum FrequencyKind { daily, onceDaily, eightHours, twelveHours, prescribed }

final class Frequency {
  const Frequency._(this.value, this.kind);
  final String value;
  final FrequencyKind kind;

  static Frequency? tryParse(String raw) {
    final value = raw.trim();
    final normalized = value
        .toLowerCase()
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('é', 'e')
        .replaceAll(RegExp(r'\s+'), ' ');
    final kind = switch (normalized) {
      'daily' || 'cada dia' || 'diaria' || 'every day' => FrequencyKind.daily,
      'una vez al dia' ||
      'cada 24 horas' ||
      'once a day' ||
      'once daily' => FrequencyKind.onceDaily,
      'cada 8 horas' || 'every 8 hours' => FrequencyKind.eightHours,
      'cada 12 horas' || 'every 12 hours' => FrequencyKind.twelveHours,
      'segun indicacion medica' || 'as prescribed' => FrequencyKind.prescribed,
      _ => null,
    };
    return kind == null || value.length > 100 ? null : Frequency._(value, kind);
  }

  String get backendValue =>
      switch (value.toLowerCase().replaceAll(RegExp(r'\s+'), ' ')) {
        'every day' => 'Cada día',
        'once a day' || 'once daily' => 'Una vez al día',
        'every 8 hours' => 'Cada 8 horas',
        'every 12 hours' => 'Cada 12 horas',
        'as prescribed' => 'Según indicación médica',
        _ => value,
      };

  int? get expectedCount => switch (kind) {
    FrequencyKind.onceDaily => 1,
    FrequencyKind.eightHours => 3,
    FrequencyKind.twelveHours => 2,
    _ => null,
  };

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
