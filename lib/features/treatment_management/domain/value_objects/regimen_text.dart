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

/// Normalized frequency description, nonblank and at most 100 characters.
final class Frequency {
  const Frequency._(this.value);
  final String value;

  static Frequency? tryParse(String raw) {
    final normalized = raw.trim();
    return normalized.isNotEmpty && normalized.length <= 100
        ? Frequency._(normalized)
        : null;
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
