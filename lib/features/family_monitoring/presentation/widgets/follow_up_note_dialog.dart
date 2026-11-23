import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/entities/notes.dart';
import '../bloc/notes/note_composer_cubit.dart';

String noteProblemText(AppLocalizations text, NoteProblem problem) =>
    switch (problem) {
      NoteProblem.blank => text.fmNoteErrorBlank,
      NoteProblem.tooLong => text.fmNoteErrorTooLong(FollowUpNote.maxLength),
      NoteProblem.rejected => text.fmNoteErrorRejected,
      NoteProblem.network => text.networkUnavailable,
      NoteProblem.accessDenied => text.fmErrorAccess,
      NoteProblem.notFound => text.fmErrorListNotFound,
      NoteProblem.unknown => text.fmNoteErrorSave,
    };

/// Composer for a follow-up note. It lives while the cubit says it is open and keeps what
/// was typed when saving fails.
class FollowUpNoteDialog extends StatefulWidget {
  const FollowUpNoteDialog({super.key});

  @override
  State<FollowUpNoteDialog> createState() => _FollowUpNoteDialogState();
}

class _FollowUpNoteDialogState extends State<FollowUpNoteDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    final cubit = context.read<NoteComposerCubit>();
    return BlocBuilder<NoteComposerCubit, NoteComposerState>(
      builder: (context, state) {
        final error = state.error;
        return AlertDialog(
          title: Text(text.fmNoteDialogTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _controller,
                enabled: !state.saving,
                minLines: 3,
                maxLines: 6,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: text.fmNoteDialogLabel,
                  border: const OutlineInputBorder(),
                  errorText: error == null
                      ? null
                      : noteProblemText(text, error),
                  errorMaxLines: 3,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                text.fmNoteDialogCounter(
                  _controller.text.length,
                  FollowUpNote.maxLength,
                ),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: state.saving ? null : cubit.dismiss,
              child: Text(text.fmCancel),
            ),
            FilledButton(
              onPressed: state.saving
                  ? null
                  : () => cubit.save(_controller.text),
              child: Text(
                state.saving ? text.fmActionSaving : text.fmNoteDialogSave,
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Shows the composer while [NoteComposerCubit] is open and closes it afterwards. The
/// dialog is driven only by the cubit, so a lost session or a clear removes it too.
class NoteComposerHost extends StatefulWidget {
  const NoteComposerHost({super.key, required this.child, this.onSaved});

  final Widget child;

  /// Called once with each note the server stored.
  final ValueChanged<FollowUpNote>? onSaved;

  @override
  State<NoteComposerHost> createState() => _NoteComposerHostState();
}

class _NoteComposerHostState extends State<NoteComposerHost> {
  bool _showing = false;

  void _sync(BuildContext context, NoteComposerState state) {
    if (state.open && !_showing) {
      _showing = true;
      final cubit = context.read<NoteComposerCubit>();
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) =>
            BlocProvider.value(value: cubit, child: const FollowUpNoteDialog()),
      ).whenComplete(() => _showing = false);
    } else if (!state.open && _showing) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  @override
  Widget build(BuildContext context) =>
      BlocListener<NoteComposerCubit, NoteComposerState>(
        listenWhen: (a, b) => a.open != b.open || a.note != b.note,
        listener: (context, state) {
          _sync(context, state);
          final note = state.note;
          if (state.saved && note != null) {
            widget.onSaved?.call(note);
            ScaffoldMessenger.maybeOf(context)?.showSnackBar(
              SnackBar(content: Text(AppLocalizations.of(context).fmNoteSaved)),
            );
          }
        },
        child: widget.child,
      );
}
