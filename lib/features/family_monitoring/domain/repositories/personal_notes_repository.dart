import '../../../../shared/common/result/app_result.dart';
import '../entities/notes.dart';
import '../value_objects/note_values.dart';

/// Reads and creates notes owned by the authenticated older adult.
abstract interface class PersonalNotesRepository {
  Future<AppResult<List<PersonalNote>>> list();

  Future<AppResult<PersonalNote>> create(
    String title,
    String text,
    PersonalNoteCategory category,
  );
}
