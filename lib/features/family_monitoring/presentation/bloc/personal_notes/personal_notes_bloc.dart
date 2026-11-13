import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../shared/common/result/app_result.dart';
import '../../../application/usecases/note_usecases.dart';
import '../../../domain/entities/notes.dart';
import '../../../domain/value_objects/note_values.dart';

sealed class PersonalNotesEvent {
  const PersonalNotesEvent();
}

final class PersonalNotesRequested extends PersonalNotesEvent {
  const PersonalNotesRequested();
}

/// A null [category] shows every note.
final class PersonalNotesFiltered extends PersonalNotesEvent {
  const PersonalNotesFiltered(this.category);
  final PersonalNoteCategory? category;
}

final class PersonalNoteComposerToggled extends PersonalNotesEvent {
  const PersonalNoteComposerToggled({required this.open});
  final bool open;
}

final class PersonalNoteSubmitted extends PersonalNotesEvent {
  const PersonalNoteSubmitted({
    required this.title,
    required this.text,
    required this.category,
  });
  final String title;
  final String text;
  final PersonalNoteCategory category;
}

/// Personal note list, category filter and composer operation state.
final class PersonalNotesState {
  const PersonalNotesState({
    this.notes = const [],
    this.loading = true,
    this.saving = false,
    this.errorCode,
    this.saveError = false,
    this.composing = false,
    this.category,
  });

  final List<PersonalNote> notes;
  final bool loading;
  final bool saving;
  final String? errorCode;
  final bool saveError;
  final bool composing;
  final PersonalNoteCategory? category;

  /// The notes belong to the signed-in adult: without that session there is nothing to show.
  bool get requiresSignIn =>
      errorCode == 'AUTHENTICATION_REQUIRED' ||
      errorCode == 'SESSION_CHANGED' ||
      errorCode == 'ACCESS_DENIED';

  List<PersonalNote> get visibleNotes => category == null
      ? notes
      : notes.where((note) => note.category == category).toList();

  PersonalNotesState copyWith({
    List<PersonalNote>? notes,
    bool? loading,
    bool? saving,
    String? Function()? errorCode,
    bool? saveError,
    bool? composing,
    PersonalNoteCategory? Function()? category,
  }) => PersonalNotesState(
    notes: notes ?? this.notes,
    loading: loading ?? this.loading,
    saving: saving ?? this.saving,
    errorCode: errorCode == null ? this.errorCode : errorCode(),
    saveError: saveError ?? this.saveError,
    composing: composing ?? this.composing,
    category: category == null ? this.category : category(),
  );
}

/// Serializes note creation against list reloads while retaining the active composer on a
/// failure, so the person does not lose what they wrote.
final class PersonalNotesBloc
    extends Bloc<PersonalNotesEvent, PersonalNotesState> {
  PersonalNotesBloc({required this._list, required this._create})
    : super(const PersonalNotesState()) {
    on<PersonalNotesRequested>(_load);
    on<PersonalNotesFiltered>(
      (event, emit) => emit(state.copyWith(category: () => event.category)),
    );
    on<PersonalNoteComposerToggled>((event, emit) {
      if (state.saving || state.requiresSignIn) return;
      emit(state.copyWith(composing: event.open, saveError: false));
    });
    on<PersonalNoteSubmitted>(_save);
  }

  final GetPersonalNotes _list;
  final CreatePersonalNote _create;
  int _revision = 0;

  Future<void> _load(
    PersonalNotesRequested event,
    Emitter<PersonalNotesState> emit,
  ) async {
    if (state.saving) return;
    final revision = ++_revision;
    emit(state.copyWith(loading: true, errorCode: () => null));
    final result = await _list();
    if (revision != _revision || emit.isDone) return;
    switch (result) {
      case AppSuccess(:final value):
        emit(state.copyWith(notes: value, loading: false));
      case AppFailure(:final code):
        final failed = state.copyWith(loading: false, errorCode: () => code);
        // Without the adult's session nothing protected remains on screen.
        emit(
          failed.requiresSignIn
              ? PersonalNotesState(loading: false, errorCode: code)
              : failed,
        );
    }
  }

  Future<void> _save(
    PersonalNoteSubmitted event,
    Emitter<PersonalNotesState> emit,
  ) async {
    if (state.requiresSignIn ||
        state.saving ||
        event.title.trim().isEmpty ||
        event.text.trim().isEmpty ||
        event.title.trim().length > PersonalNote.maxTitleLength ||
        event.text.trim().length > PersonalNote.maxTextLength) {
      return;
    }
    _revision++;
    emit(state.copyWith(saving: true, loading: false, saveError: false));
    final result = await _create(event.title, event.text, event.category);
    if (emit.isDone) return;
    switch (result) {
      case AppSuccess(:final value):
        emit(
          state.copyWith(
            notes: [value, ...state.notes.where((note) => note.id != value.id)],
            saving: false,
            composing: false,
          ),
        );
      case AppFailure(:final code):
        final failed = state.copyWith(errorCode: () => code);
        emit(
          failed.requiresSignIn
              ? PersonalNotesState(loading: false, errorCode: code)
              : state.copyWith(saving: false, saveError: true),
        );
    }
  }
}
