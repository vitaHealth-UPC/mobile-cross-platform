import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../shared/common/result/app_result.dart';
import '../../../application/ports/monitoring_ports.dart';
import '../../../application/readmodels/monitoring_readmodels.dart';
import '../../../application/usecases/note_usecases.dart';
import '../../../domain/entities/notes.dart';
import '../../texts/monitoring_texts.dart';

sealed class NotesEvent {
  const NotesEvent();
}

/// Load or reload the notes; also sent when the screen resumes.
final class NotesRequested extends NotesEvent {
  const NotesRequested();
}

/// A note the server acknowledged goes on top at once; the next load brings server order.
final class NoteAdded extends NotesEvent {
  const NoteAdded(this.note);
  final FollowUpNote note;
}

/// Access was lost while writing: nothing protected stays on screen.
final class NotesAccessLost extends NotesEvent {
  const NotesAccessLost(this.code);
  final String code;
}

enum NotesStatus { loading, ready, empty, failure }

final class NotesState {
  const NotesState({
    this.status = NotesStatus.loading,
    this.notes = const [],
    this.person,
    this.errorCode,
  });

  final NotesStatus status;
  final List<FollowUpNote> notes;
  final MonitoredPerson? person;
  final String? errorCode;
}

/// Loads the caregiver follow-up notes of one adult and the profile that frames them.
final class NotesBloc extends Bloc<NotesEvent, NotesState> {
  NotesBloc({
    required this._notes,
    required this._people,
    required this.olderAdultId,
  }) : super(const NotesState()) {
    on<NotesRequested>(_load);
    on<NoteAdded>(_add);
    on<NotesAccessLost>((event, emit) {
      _revision++;
      emit(NotesState(status: NotesStatus.failure, errorCode: event.code));
    });
  }

  final GetFollowUpNotes _notes;
  final MonitoredPersonReader _people;
  final String olderAdultId;
  int _revision = 0;

  Future<void> _load(NotesRequested event, Emitter<NotesState> emit) async {
    final revision = ++_revision;
    final kept = state.status == NotesStatus.ready
        ? state.notes
        : const <FollowUpNote>[];
    if (state.status != NotesStatus.ready) emit(const NotesState());
    final result = await _notes(olderAdultId);
    if (revision != _revision || emit.isDone) return;
    switch (result) {
      case AppSuccess(:final value):
        emit(
          NotesState(
            status: value.isEmpty ? NotesStatus.empty : NotesStatus.ready,
            notes: value,
          ),
        );
      case AppFailure(:final code):
        emit(
          NotesState(
            status: NotesStatus.failure,
            notes: isAccessFailure(code) ? const [] : kept,
            errorCode: code,
          ),
        );
        return;
    }
    final profile = await _people.read(olderAdultId);
    if (revision != _revision || emit.isDone) return;
    switch (profile) {
      case AppSuccess(:final value):
        emit(
          NotesState(status: state.status, notes: state.notes, person: value),
        );
      case AppFailure(:final code) when isAccessFailure(code):
        emit(NotesState(status: NotesStatus.failure, errorCode: code));
      case AppFailure():
        break;
    }
  }

  void _add(NoteAdded event, Emitter<NotesState> emit) {
    _revision++;
    emit(
      NotesState(
        status: NotesStatus.ready,
        notes: [
          event.note,
          ...state.notes.where((note) => note.id != event.note.id),
        ],
        person: state.person,
      ),
    );
  }
}
