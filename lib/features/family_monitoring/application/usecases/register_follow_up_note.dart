import '../../../../shared/common/result/app_result.dart';
import '../../domain/entities/notes.dart';
import '../../domain/repositories/notes_repository.dart';
import '../../domain/value_objects/note_values.dart';
import '../failure_codes.dart';

/// Registers a note written by the caregiver; the text is trimmed and checked before it is
/// sent.
final class RegisterFollowUpNote {
  const RegisterFollowUpNote(this._repository);
  final NotesRepository _repository;

  Future<AppResult<FollowUpNote>> call(String olderAdultId, String text) async {
    if (olderAdultId.trim().isEmpty) {
      return const AppFailure(MonitoringFailureCodes.invalidReference);
    }
    return switch (FollowUpNote.problemWith(text)) {
      NoteTextProblem.blank => const AppFailure(
        MonitoringFailureCodes.noteBlank,
      ),
      NoteTextProblem.tooLong => const AppFailure(
        MonitoringFailureCodes.noteTooLong,
      ),
      null => await _repository.register(olderAdultId.trim(), text.trim()),
    };
  }
}
