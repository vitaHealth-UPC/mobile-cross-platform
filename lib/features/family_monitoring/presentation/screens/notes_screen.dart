import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/application/time/clock.dart';
import '../../../../shared/presentation/theme/tata_colors.dart';
import '../../../../shared/presentation/widgets/caregiver_tab_bar.dart';
import '../bloc/notes/note_composer_cubit.dart';
import '../bloc/notes/notes_bloc.dart';
import '../texts/monitoring_texts.dart';
import '../widgets/follow_up_note_card.dart';
import '../widgets/follow_up_note_dialog.dart';
import '../widgets/monitoring_widgets.dart';

/// Authorized caregiver notes with a native profile, timeline and composer.
class NotesScreen extends StatelessWidget {
  const NotesScreen({
    super.key,
    required this.onTab,
    this.clock = DateTime.now,
  });
  final ValueChanged<CaregiverTab> onTab;
  final Clock clock;

  Future<void> _refresh(BuildContext context) async {
    final bloc = context.read<NotesBloc>();
    if (bloc.state.refreshing || bloc.state.status == NotesStatus.loading) {
      return;
    }
    final completed = bloc.stream.firstWhere(
      (state) => !state.refreshing,
      orElse: () => bloc.state,
    );
    bloc.add(const NotesRequested());
    await completed;
  }

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    return NoteComposerHost(
      onSaved: (note) => context.read<NotesBloc>().add(NoteAdded(note)),
      child: MultiBlocListener(
        listeners: [
          BlocListener<NoteComposerCubit, NoteComposerState>(
            listenWhen: (a, b) => a.failureCode != b.failureCode,
            listener: (context, state) {
              final code = state.failureCode;
              if (code != null && isAccessFailure(code)) {
                context.read<NotesBloc>().add(NotesAccessLost(code));
                context.read<NoteComposerCubit>().clear();
              }
            },
          ),
          BlocListener<NotesBloc, NotesState>(
            listenWhen: (a, b) => a.errorCode != b.errorCode,
            listener: (context, state) {
              if (isAccessFailure(state.errorCode)) {
                context.read<NoteComposerCubit>().clear();
              }
            },
          ),
        ],
        child: Scaffold(
          backgroundColor: const Color(0xFFFBFBFE),
          extendBody: true,
          bottomNavigationBar: CaregiverTabBar(
            selected: CaregiverTab.notes,
            onSelected: onTab,
          ),
          body: SafeArea(
            bottom: false,
            child: BlocBuilder<NotesBloc, NotesState>(
              builder: (context, state) {
                final person = state.person;
                final denied = isAccessFailure(state.errorCode);
                final add =
                    denied ||
                        state.refreshing ||
                        state.status == NotesStatus.loading
                    ? null
                    : () => context.read<NoteComposerCubit>().open();
                final now = clock();
                return RefreshIndicator(
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
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: MonitoringHeader(
                                title: text.fmNotesTitle,
                                subtitle: person == null
                                    ? text.fmNotesSubtitle
                                    : text.fmNotesSubtitlePerson(
                                        person.fullName,
                                      ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              tooltip: text.fmNotesAdd,
                              onPressed: add,
                              icon: const Icon(
                                Icons.add,
                                color: TataColors.primary,
                              ),
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.white,
                                side: const BorderSide(
                                  color: Color(0xFFE3E3F0),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        if (person != null && !denied) ...[
                          FollowUpPersonCard(person: person, now: now),
                          const SizedBox(height: 24),
                        ],
                        switch (state.status) {
                          NotesStatus.loading => MonitoringLoading(
                            label: text.fmNotesLoading,
                          ),
                          NotesStatus.failure => MonitoringError(
                            message: denied
                                ? text.fmErrorAccess
                                : text.fmErrorUnknown,
                            onRetry: denied
                                ? null
                                : () => context.read<NotesBloc>().add(
                                    const NotesRequested(),
                                  ),
                          ),
                          NotesStatus.empty => MonitoringCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  text.fmNotesEmptyTitle,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(text.fmNotesEmptyMessage),
                              ],
                            ),
                          ),
                          NotesStatus.ready => Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                text.fmNotesSection,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Stack(
                                children: [
                                  Positioned(
                                    left: 31,
                                    top: 24,
                                    bottom: 24,
                                    width: 2,
                                    child: ColoredBox(
                                      color: const Color(0xFFE5E4EE),
                                    ),
                                  ),
                                  Column(
                                    children: [
                                      for (
                                        var i = 0;
                                        i < state.notes.length;
                                        i++
                                      ) ...[
                                        FollowUpNoteCard(
                                          note: state.notes[i],
                                          now: now,
                                          index: i,
                                        ),
                                        const SizedBox(height: 16),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        },
                        if (!denied) ...[
                          const SizedBox(height: 4),
                          MonitoringCard(
                            color: const Color(0xFFE8F7EB),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  text.fmNotesSharedHistory,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  text.fmNotesSharedHistoryBody,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    height: 1.3,
                                    color: Color(0xFF637087),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          MonitoringPrimaryButton(
                            label: text.fmNotesAdd,
                            onPressed: add,
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
