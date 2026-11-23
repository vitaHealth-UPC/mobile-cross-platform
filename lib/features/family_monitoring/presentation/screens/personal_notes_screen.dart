import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/presentation/theme/tata_colors.dart';
import '../../../../shared/presentation/widgets/adult_navigation_bar.dart';
import '../../domain/entities/notes.dart';
import '../../domain/value_objects/note_values.dart';
import '../bloc/personal_notes/personal_notes_bloc.dart';
import '../texts/monitoring_texts.dart';
import '../widgets/monitoring_widgets.dart';

/// Older adult's own notes, filtered by category.
class PersonalNotesScreen extends StatelessWidget {
  const PersonalNotesScreen({
    super.key,
    this.onHome,
    this.onMedications,
    this.onAgenda,
    this.onMore,
    this.onSignIn,
  });

  final VoidCallback? onHome;
  final VoidCallback? onMedications;
  final VoidCallback? onAgenda;
  final VoidCallback? onMore;

  /// Sends the person back to sign in when the session no longer allows reading notes.
  final VoidCallback? onSignIn;

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    return BlocConsumer<PersonalNotesBloc, PersonalNotesState>(
      listenWhen: (a, b) => !a.composing && b.composing,
      listener: (context, state) => _compose(context),
      builder: (context, state) {
        final notes = state.visibleNotes;
        return Scaffold(
          backgroundColor: TataColors.background,
          extendBody: true,
          bottomNavigationBar: AdultNavigationBar(
            selected: AdultDestination.notes,
            onHome: onHome,
            onMedications: onMedications,
            onAgenda: onAgenda,
            onNotes: () {},
            onMore: onMore,
          ),
          body: SafeArea(
            bottom: false,
            child: RefreshIndicator(
              onRefresh: () async => context.read<PersonalNotesBloc>().add(
                const PersonalNotesRequested(),
              ),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  22,
                  22,
                  22,
                  MediaQuery.paddingOf(context).bottom + 110,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MonitoringHeader(
                      title: text.pnTitle,
                      subtitle: text.pnSubtitle,
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        MonitoringFilterChip(
                          label: text.pnAll,
                          selected: state.category == null,
                          onTap: () => context.read<PersonalNotesBloc>().add(
                            const PersonalNotesFiltered(null),
                          ),
                        ),
                        for (final category in PersonalNoteCategory.values)
                          MonitoringFilterChip(
                            label: category == PersonalNoteCategory.medication
                                ? text.pnMedications
                                : text.pnRoutine,
                            selected: state.category == category,
                            onTap: () => context.read<PersonalNotesBloc>().add(
                              PersonalNotesFiltered(category),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (state.loading)
                      MonitoringLoading(label: text.pnToday)
                    else if (state.errorCode != null)
                      MonitoringError(
                        message: text.pnLoadError,
                        onRetry: state.requiresSignIn
                            ? onSignIn
                            : () => context.read<PersonalNotesBloc>().add(
                                const PersonalNotesRequested(),
                              ),
                      )
                    else if (notes.isEmpty)
                      Text(
                        text.pnEmpty,
                        style: const TextStyle(color: TataColors.muted),
                      )
                    else
                      for (final note in notes) ...[
                        _NoteCard(note: note),
                        const SizedBox(height: 12),
                      ],
                    const SizedBox(height: 8),
                    MonitoringCard(
                      color: const Color(0xFFFFF5DE),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            text.pnTip,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          Text(text.pnTipText),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    MonitoringPrimaryButton(
                      label: text.pnAdd,
                      onPressed: state.requiresSignIn
                          ? null
                          : () => context.read<PersonalNotesBloc>().add(
                              const PersonalNoteComposerToggled(open: true),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _compose(BuildContext context) async {
    final bloc = context.read<PersonalNotesBloc>();
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          BlocProvider.value(value: bloc, child: const _PersonalNoteDialog()),
    );
    if (bloc.state.composing && !bloc.state.saving) {
      bloc.add(const PersonalNoteComposerToggled(open: false));
    }
  }
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({required this.note});
  final PersonalNote note;

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    return MonitoringCard(
      color: note.category == PersonalNoteCategory.medication
          ? TataColors.lavender
          : Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            note.title,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(note.text),
          const SizedBox(height: 6),
          Text(
            '${note.category == PersonalNoteCategory.medication ? text.pnMedications : text.pnRoutine}'
            ' · ${monitoringDateTime(locale, note.recordedAt)}',
            style: const TextStyle(color: TataColors.muted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _PersonalNoteDialog extends StatefulWidget {
  const _PersonalNoteDialog();

  @override
  State<_PersonalNoteDialog> createState() => _PersonalNoteDialogState();
}

class _PersonalNoteDialogState extends State<_PersonalNoteDialog> {
  final _title = TextEditingController();
  final _body = TextEditingController();
  PersonalNoteCategory _category = PersonalNoteCategory.routine;

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    return BlocConsumer<PersonalNotesBloc, PersonalNotesState>(
      listenWhen: (a, b) => a.composing && !b.composing,
      listener: (context, state) => Navigator.of(context).maybePop(),
      builder: (context, state) {
        final canSave =
            !state.saving &&
            _title.text.trim().isNotEmpty &&
            _body.text.trim().isNotEmpty;
        return AlertDialog(
          title: Text(text.pnAdd),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _title,
                  enabled: !state.saving,
                  maxLength: PersonalNote.maxTitleLength,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(labelText: text.pnSubject),
                ),
                TextField(
                  controller: _body,
                  enabled: !state.saving,
                  maxLength: PersonalNote.maxTextLength,
                  minLines: 3,
                  maxLines: 6,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(labelText: text.pnBody),
                ),
                const SizedBox(height: 8),
                SegmentedButton<PersonalNoteCategory>(
                  segments: [
                    ButtonSegment(
                      value: PersonalNoteCategory.medication,
                      label: Text(text.pnMedications),
                    ),
                    ButtonSegment(
                      value: PersonalNoteCategory.routine,
                      label: Text(text.pnRoutine),
                    ),
                  ],
                  selected: {_category},
                  onSelectionChanged: state.saving
                      ? null
                      : (value) => setState(() => _category = value.first),
                ),
                if (state.saveError)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      text.pnSaveError,
                      style: const TextStyle(color: TataColors.errorText),
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: state.saving
                  ? null
                  : () => context.read<PersonalNotesBloc>().add(
                      const PersonalNoteComposerToggled(open: false),
                    ),
              child: Text(text.pnCancel),
            ),
            FilledButton(
              onPressed: canSave
                  ? () => context.read<PersonalNotesBloc>().add(
                      PersonalNoteSubmitted(
                        title: _title.text,
                        text: _body.text,
                        category: _category,
                      ),
                    )
                  : null,
              child: Text(state.saving ? text.fmActionSaving : text.pnSave),
            ),
          ],
        );
      },
    );
  }
}
