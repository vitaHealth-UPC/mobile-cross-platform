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
    this.refreshing = false,
  });

  final NotesStatus status;
  final List<FollowUpNote> notes;
  final MonitoredPerson? person;
  final String? errorCode;

  /// Remains true until both notes and profile queries have finished.
  final bool refreshing;
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
    final kept = state.notes;
    final knownPerson = state.person;
    emit(
      NotesState(
        status: state.status,
        notes: kept,
        person: knownPerson,
        refreshing: true,
      ),
    );
    final result = await _notes(olderAdultId);
    if (revision != _revision || emit.isDone) return;
    if (result is AppFailure<List<FollowUpNote>>) {
      final denied = isAccessFailure(result.code);
      emit(
        NotesState(
          status: NotesStatus.failure,
          notes: denied ? const [] : kept,
          person: denied ? null : knownPerson,
          errorCode: result.code,
        ),
      );
      return;
    }
    final notes = (result as AppSuccess<List<FollowUpNote>>).value;
    // Do not publish newly fetched text before the profile access check finishes.
    final profile = await _people.read(olderAdultId);
    if (revision != _revision || emit.isDone) return;
    if (profile is AppFailure<MonitoredPerson> &&
        isAccessFailure(profile.code)) {
      emit(NotesState(status: NotesStatus.failure, errorCode: profile.code));
      return;
    }
    emit(
      NotesState(
        status: notes.isEmpty ? NotesStatus.empty : NotesStatus.ready,
        notes: notes,
        person: profile is AppSuccess<MonitoredPerson>
            ? profile.value
            : knownPerson,
      ),
    );
  }

  void _add(NoteAdded event, Emitter<NotesState> emit) {
    if (isAccessFailure(state.errorCode)) return;
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
