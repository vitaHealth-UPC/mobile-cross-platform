/// Validation result for a caregiver's follow-up note text.
enum NoteTextProblem { blank, tooLong }

/// Purpose of an older adult's personal reminder.
enum PersonalNoteCategory {
  medication('MEDICATION'),
  routine('ROUTINE');

  const PersonalNoteCategory(this.wireName);
  final String wireName;

  static PersonalNoteCategory? fromWire(Object? value) {
    for (final category in values) {
      if (category.wireName == value) return category;
    }
    return null;
  }
}
