/// Authorized profile evidence; an absent birth date never becomes a guessed age.
final class MonitoredPerson {
  const MonitoredPerson({
    required this.id,
    required this.fullName,
    required this.birthDate,
  });
  final String id;
  final String fullName;
  final DateTime? birthDate;

  /// Whole years at [now], or null when the profile has no birth date.
  int? ageAt(DateTime now) {
    final born = birthDate;
    if (born == null) return null;
    var years = now.year - born.year;
    if (now.month < born.month ||
        (now.month == born.month && now.day < born.day)) {
      years--;
    }
    return years < 0 ? null : years;
  }
}
