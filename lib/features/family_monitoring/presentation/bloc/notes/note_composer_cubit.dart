import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../shared/common/result/app_result.dart';
import '../../../application/failure_codes.dart';
import '../../../application/usecases/note_usecases.dart';
import '../../../domain/entities/notes.dart';
import '../../../domain/value_objects/note_values.dart';

/// Why saving a follow-up note failed, as the composer explains it.
enum NoteProblem {
  blank,
  tooLong,
  rejected,
  network,
  accessDenied,
  notFound,
  unknown,
}

NoteProblem noteProblemOf(String code) => switch (code) {
  MonitoringFailureCodes.noteBlank => NoteProblem.blank,
  MonitoringFailureCodes.noteTooLong => NoteProblem.tooLong,
  MonitoringFailureCodes.noteRejected => NoteProblem.rejected,
  'NETWORK_UNAVAILABLE' => NoteProblem.network,
  'ACCESS_DENIED' ||
  'AUTHENTICATION_REQUIRED' ||
  'SESSION_CHANGED' => NoteProblem.accessDenied,
  MonitoringFailureCodes.notFound => NoteProblem.notFound,
  _ => NoteProblem.unknown,
};

/// [saved] stays true after a note is stored, so the screen can show "Nota guardada" until
/// the next note; [note] is that note, for the screens that list it.
final class NoteComposerState {
  const NoteComposerState({
    this.open = false,
    this.saving = false,
    this.error,
    this.saved = false,
    this.note,
    this.failureCode,
  });

  final bool open;
  final bool saving;
  final NoteProblem? error;
  final bool saved;
  final FollowUpNote? note;

  /// Raw code of the last failure, for the host to tell an ended session apart.
  final String? failureCode;
}

/// Write-a-note flow shared by the notes screen and the alert detail.
final class NoteComposerCubit extends Cubit<NoteComposerState> {
  NoteComposerCubit({required this._register, required this.olderAdultId})
    : super(const NoteComposerState());

  final RegisterFollowUpNote _register;
  final String olderAdultId;
  int _revision = 0;

  /// Discards the protected draft and prevents a late save from reopening it.
  void clear() {
    _revision++;
    emit(const NoteComposerState());
  }

  void open() {
    if (state.saving) return;
    emit(const NoteComposerState(open: true));
  }

  void dismiss() {
    if (state.saving) return;
    emit(NoteComposerState(saved: state.saved, note: state.note));
  }

  Future<void> save(String text) async {
    final current = state;
    if (!current.open || current.saving) return;
    switch (FollowUpNote.problemWith(text)) {
      case NoteTextProblem.blank:
        emit(
          NoteComposerState(
            open: true,
            error: NoteProblem.blank,
            note: current.note,
          ),
        );
        return;
      case NoteTextProblem.tooLong:
        emit(
          NoteComposerState(
            open: true,
            error: NoteProblem.tooLong,
            note: current.note,
          ),
        );
        return;
      case null:
        break;
    }
    final revision = ++_revision;
    emit(NoteComposerState(open: true, saving: true, note: current.note));
    final result = await _register(olderAdultId, text);
    if (revision != _revision || isClosed) return;
    switch (result) {
      case AppSuccess(:final value):
        emit(NoteComposerState(saved: true, note: value));
      case AppFailure(:final code):
        emit(
          NoteComposerState(
            open: true,
            error: noteProblemOf(code),
            note: current.note,
            failureCode: code,
          ),
        );
    }
  }
}
