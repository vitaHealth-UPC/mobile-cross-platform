import '../../../../shared/common/result/app_result.dart';
import '../../domain/entities/notes.dart';
import '../../domain/repositories/monitoring_repositories.dart';
import '../../domain/value_objects/note_values.dart';
import '../failure_codes.dart';

/// Notes of the follow-up, most recent first.
final class GetFollowUpNotes {
  const GetFollowUpNotes(this._repository);
  final NotesRepository _repository;

  Future<AppResult<List<FollowUpNote>>> call(String olderAdultId) async {
    if (olderAdultId.trim().isEmpty) {
      return const AppFailure(MonitoringFailureCodes.invalidReference);
    }
    return switch (await _repository.notes(olderAdultId.trim())) {
      AppSuccess(:final value) => AppSuccess(
        List.unmodifiable(
          [...value]..sort((a, b) => b.recordedAt.compareTo(a.recordedAt)),
        ),
      ),
      AppFailure(:final code) => AppFailure(code),
    };
  }
}

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

/// Lists the current session owner's personal notes.
final class GetPersonalNotes {
  const GetPersonalNotes(this._repository);
  final PersonalNotesRepository _repository;

  Future<AppResult<List<PersonalNote>>> call() => _repository.list();
}

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
