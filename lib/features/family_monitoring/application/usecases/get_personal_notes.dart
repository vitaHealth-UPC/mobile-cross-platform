import '../../../../shared/common/result/app_result.dart';
import '../../domain/entities/notes.dart';
import '../../domain/repositories/personal_notes_repository.dart';

/// Lists the current session owner's personal notes.
final class GetPersonalNotes {
  const GetPersonalNotes(this._repository);
  final PersonalNotesRepository _repository;

  Future<AppResult<List<PersonalNote>>> call() => _repository.list();
}
