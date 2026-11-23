import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/application/time/clock.dart';
import '../../../../shared/presentation/theme/tata_colors.dart';
import '../../../../shared/presentation/theme/tata_typography.dart';
import '../../../../shared/presentation/widgets/adult_navigation_bar.dart';
import '../../domain/entities/notes.dart';
import '../../domain/value_objects/note_values.dart';
import '../bloc/personal_notes/personal_notes_bloc.dart';
import '../widgets/monitoring_widgets.dart';
import '../widgets/personal_note_card.dart';

/// Older adult's own notes, filtered by category.
class PersonalNotesScreen extends StatelessWidget {
  const PersonalNotesScreen({
    super.key,
    this.onHome,
    this.onMedications,
    this.onAgenda,
    this.onMore,
    this.onSignIn,
    this.clock = DateTime.now,
  });

  final VoidCallback? onHome;
  final VoidCallback? onMedications;
  final VoidCallback? onAgenda;
  final VoidCallback? onMore;

  /// Sends the person back to sign in when the session no longer allows reading notes.
  final VoidCallback? onSignIn;

  /// Local calendar used for grouping; note instants remain server evidence.
  final Clock clock;

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    return BlocConsumer<PersonalNotesBloc, PersonalNotesState>(
      listenWhen: (a, b) =>
          (!a.composing && b.composing) ||
          (a.saving &&
              !b.saving &&
              !b.saveError &&
              !b.requiresSignIn &&
              !b.composing),
      listener: (context, state) {
        if (state.composing) {
          _compose(context);
        } else {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(text.fmNoteSaved)));
        }
      },
      builder: (context, state) {
        final notes = state.visibleNotes;
        final now = clock().toLocal();
        final today = notes
            .where((n) => DateUtils.isSameDay(n.recordedAt.toLocal(), now))
            .toList();
        final recent = notes
            .where((n) => !DateUtils.isSameDay(n.recordedAt.toLocal(), now))
            .toList();
        final add = state.requiresSignIn || state.saving || state.loading
            ? null
            : () => context.read<PersonalNotesBloc>().add(
                const PersonalNoteComposerToggled(open: true),
              );
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
              onRefresh: () => _refresh(context),
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
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Semantics(
                                header: true,
                                child: Text(
                                  text.pnTitle,
                                  style: TataTypography.heading.copyWith(
                                    fontSize: 28,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                text.pnSubtitle,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF5B6475),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filledTonal(
                          onPressed: add,
                          tooltip: text.pnAdd,
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: TataColors.primary,
                            side: const BorderSide(color: Color(0xFFE3E3F0)),
                          ),
                          icon: const Icon(Icons.add, size: 24),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      today.isNotEmpty ? text.pnToday : text.pnRecent,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: TataColors.ink,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        IntrinsicWidth(
                          child: MonitoringFilterChip(
                            fontSize: 11,
                            label: text.pnAll,
                            selected: state.category == null,
                            onTap: () => context.read<PersonalNotesBloc>().add(
                              const PersonalNotesFiltered(null),
                            ),
                          ),
                        ),
                        for (final category in PersonalNoteCategory.values)
                          IntrinsicWidth(
                            child: MonitoringFilterChip(
                              fontSize: 11,
                              label: category == PersonalNoteCategory.medication
                                  ? text.pnMedications
                                  : text.pnRoutine,
                              selected: state.category == category,
                              onTap: () => context
                                  .read<PersonalNotesBloc>()
                                  .add(PersonalNotesFiltered(category)),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (state.loading && notes.isEmpty)
                      MonitoringLoading(label: text.pnToday)
                    else if (state.errorCode != null)
                      MonitoringError(
                        message: text.pnLoadError,
                        retryLabel: state.requiresSignIn ? text.pnSignIn : null,
                        onRetry: state.requiresSignIn
                            ? onSignIn
                            : () => context.read<PersonalNotesBloc>().add(
                                const PersonalNotesRequested(),
                              ),
                      ),
                    if (!state.loading &&
                        state.errorCode == null &&
                        notes.isEmpty)
                      Text(
                        text.pnEmpty,
                        style: const TextStyle(color: TataColors.muted),
                      ),
                    if (!state.loading || notes.isNotEmpty) ...[
                      for (final note in today) ...[
                        PersonalNoteCard(note: note, now: now, highlight: true),
                        const SizedBox(height: 16),
                      ],
                      if (today.isNotEmpty && recent.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          text.pnRecent,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: TataColors.ink,
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                      for (var i = 0; i < recent.length; i++) ...[
                        PersonalNoteCard(
                          note: recent[i],
                          now: now,
                          blue: i.isOdd,
                        ),
                        const SizedBox(height: 16),
                      ],
                    ],
                    const SizedBox(height: 8),
                    MonitoringCard(
                      color: const Color(0xFFFFF5DE),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            text.pnTip,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            text.pnTipText,
                            style: const TextStyle(
                              fontSize: 11,
                              height: 1.35,
                              color: Color(0xFF5B6475),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    MonitoringPrimaryButton(label: text.pnAdd, onPressed: add),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _refresh(BuildContext context) async {
    final bloc = context.read<PersonalNotesBloc>();
    if (bloc.state.saving) return;
    bloc.add(const PersonalNotesRequested());
    await bloc.stream.firstWhere((s) => !s.loading, orElse: () => bloc.state);
  }

  Future<void> _compose(BuildContext context) async {
    final bloc = context.read<PersonalNotesBloc>();
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          BlocProvider.value(value: bloc, child: const _PersonalNoteDialog()),
    );
    if (!bloc.isClosed && bloc.state.composing && !bloc.state.saving) {
      bloc.add(const PersonalNoteComposerToggled(open: false));
    }
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
      listener: (context, state) {
        // System Back may already be dismissing this dialog when composition resets.
        if (ModalRoute.of(context)?.isCurrent == true) {
          Navigator.of(context).pop();
        }
      },
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
