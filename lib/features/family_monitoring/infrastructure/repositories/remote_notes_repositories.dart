import '../../../../shared/application/session/session_store.dart';
import '../../../../shared/common/result/app_result.dart';
import '../../application/failure_codes.dart';
import '../../domain/entities/notes.dart';
import '../../domain/repositories/monitoring_repositories.dart';
import '../../domain/value_objects/note_values.dart';
import '../mappers/monitoring_mapper.dart';
import '../remote/family_monitoring_api.dart';
import 'monitoring_requests.dart';

/// Reads and registers caregiver-authored follow-up notes through the HTTP contract.
final class RemoteNotesRepository implements NotesRepository {
  const RemoteNotesRepository({required this._api, required this._store});
  final FamilyMonitoringApi _api;
  final SessionStore _store;

  @override
  Future<AppResult<List<FollowUpNote>>> notes(String olderAdultId) =>
      caregiverMonitoringRequest(
        _store,
        (session) =>
            _api.notes(olderAdultId, session.owner.id, session.accessToken),
        (response, _) =>
            AppSuccess(MonitoringMapper.followUpNotes(response.body)),
      );

  /// The caregiver is the author: `familiarId` takes the caregiver id of the session.
  @override
  Future<AppResult<FollowUpNote>> register(String olderAdultId, String text) =>
      caregiverMonitoringRequest(
        _store,
        (session) => _api.registerNote(
          olderAdultId,
          session.owner.id,
          text,
          session.accessToken,
        ),
        (response, owner) {
          final note = MonitoringMapper.followUpNote(response.body);
          return note.familiarId == owner.id && note.text.trim() == text.trim()
              ? AppSuccess(note)
              : const AppFailure('INVALID_RESPONSE');
        },
        badRequest: MonitoringFailureCodes.noteRejected,
      );
}

/// Retrieves and creates personal notes for the authenticated older-adult session.
final class RemotePersonalNotesRepository implements PersonalNotesRepository {
  const RemotePersonalNotesRepository({
    required this._api,
    required this._store,
  });
  final FamilyMonitoringApi _api;
  final SessionStore _store;

  @override
  Future<AppResult<List<PersonalNote>>> list() => adultMonitoringRequest(
    _store,
    (session) => _api.personalNotes(session.accessToken),
    (response, _) => AppSuccess(MonitoringMapper.personalNotes(response.body)),
  );

  @override
  Future<AppResult<PersonalNote>> create(
    String title,
    String text,
    PersonalNoteCategory category,
  ) => adultMonitoringRequest(
    _store,
    (session) => _api.createPersonalNote(
      title,
      text,
      category.wireName,
      session.accessToken,
    ),
    (response, _) {
      final note = MonitoringMapper.personalNote(response.body);
      return note.title == title.trim() &&
              note.text == text.trim() &&
              note.category == category
          ? AppSuccess(note)
          : const AppFailure('INVALID_RESPONSE');
    },
  );
}
