import '../../../../shared/common/result/app_result.dart';
import '../../domain/entities/notes.dart';
import '../../domain/repositories/personal_notes_repository.dart';
import '../../domain/value_objects/note_values.dart';
import '../failure_codes.dart';

/// Validates the note and delegates to its authorized repository port.
final class CreatePersonalNote {
  const CreatePersonalNote(this._repository);
  final PersonalNotesRepository _repository;

  Future<AppResult<PersonalNote>> call(
    String title,
    String text,
    PersonalNoteCategory category,
  ) async {
    final cleanTitle = title.trim();
    final cleanText = text.trim();
    if (cleanTitle.isEmpty ||
        cleanText.isEmpty ||
        cleanTitle.length > PersonalNote.maxTitleLength ||
        cleanText.length > PersonalNote.maxTextLength) {
      return const AppFailure(MonitoringFailureCodes.noteRejected);
    }
    return _repository.create(cleanTitle, cleanText, category);
  }
}
