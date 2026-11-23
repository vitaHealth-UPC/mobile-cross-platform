import '../../../../shared/common/result/app_result.dart';
import '../../domain/entities/notes.dart';
import '../../domain/repositories/notes_repository.dart';
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
