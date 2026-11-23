import '../value_objects/note_values.dart';

/// Follow-up note a caregiver writes about an older adult. Notes belong to the follow-up,
/// not to one alert.
final class FollowUpNote {
  FollowUpNote({
    required this.id,
    required this.text,
    required this.recordedAt,
    required this.familiarId,
  }) {
    if (id <= 0) throw ArgumentError('Note id must be positive');
  }

  /// `maxLength` of the backend `CreateCaregiverNoteResource.text`.
  static const maxLength = 1000;

  final int id;
  final String text;
  final DateTime recordedAt;

  /// The caregiver who wrote it.
  final String familiarId;

  /// The backend accepts an empty text; the app does not, because a blank note says nothing.
  static NoteTextProblem? problemWith(String text) {
    if (text.trim().isEmpty) return NoteTextProblem.blank;
    if (text.trim().length > maxLength) return NoteTextProblem.tooLong;
    return null;
  }
}

/// Personal reminder owned by the PIN user; caregiver interventions use [FollowUpNote].
final class PersonalNote {
  PersonalNote({
    required this.id,
    required this.title,
    required this.text,
    required this.category,
    required this.recordedAt,
  });

  static const maxTitleLength = 100;
  static const maxTextLength = 1000;

  final int id;
  final String title;
  final String text;
  final PersonalNoteCategory category;
  final DateTime recordedAt;
}
