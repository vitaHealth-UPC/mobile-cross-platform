import '../../../../shared/common/result/app_result.dart';
import '../entities/notes.dart';

/// Reads and records caregiver follow-up notes without binding them to one alert.
abstract interface class NotesRepository {
  Future<AppResult<List<FollowUpNote>>> notes(String olderAdultId);

  Future<AppResult<FollowUpNote>> register(String olderAdultId, String text);
}
