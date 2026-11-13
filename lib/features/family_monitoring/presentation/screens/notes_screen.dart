import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/presentation/theme/tata_colors.dart';
import '../../../../shared/presentation/widgets/caregiver_tab_bar.dart';
import '../bloc/notes/note_composer_cubit.dart';
import '../bloc/notes/notes_bloc.dart';
import '../texts/monitoring_texts.dart';
import '../widgets/follow_up_note_dialog.dart';
import '../widgets/monitoring_widgets.dart';

/// Caregiver follow-up notes about the followed person, newest first.
class NotesScreen extends StatelessWidget {
  const NotesScreen({super.key, required this.onTab});

  final ValueChanged<CaregiverTab> onTab;

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    return NoteComposerHost(
      onSaved: (note) => context.read<NotesBloc>().add(NoteAdded(note)),
      child: BlocListener<NoteComposerCubit, NoteComposerState>(
        listenWhen: (a, b) => a.failureCode != b.failureCode,
        listener: (context, state) {
          final code = state.failureCode;
          if (code != null && isAccessFailure(code)) {
            context.read<NotesBloc>().add(NotesAccessLost(code));
            context.read<NoteComposerCubit>().clear();
          }
        },
        child: Scaffold(
          backgroundColor: TataColors.background,
          extendBody: true,
          bottomNavigationBar: DefaultTextStyle.merge(
            style: const TextStyle(letterSpacing: 0, height: 1.2),
            child: CaregiverTabBar(
              selected: CaregiverTab.notes,
              onSelected: onTab,
            ),
          ),
          body: SafeArea(
            bottom: false,
            child: BlocBuilder<NotesBloc, NotesState>(
              builder: (context, state) {
                final person = state.person;
                return RefreshIndicator(
                  onRefresh: () async =>
                      context.read<NotesBloc>().add(const NotesRequested()),
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
                          title: text.fmNotesTitle,
                          subtitle: person == null
                              ? text.fmNotesSubtitle
                              : text.fmNotesSubtitlePerson(person.fullName),
                        ),
                        const SizedBox(height: 16),
                        if (state.status != NotesStatus.failure ||
                            !isAccessFailure(state.errorCode))
                          MonitoringPrimaryButton(
                            label: text.fmNotesAdd,
                            onPressed: () =>
                                context.read<NoteComposerCubit>().open(),
                          ),
                        const SizedBox(height: 16),
                        switch (state.status) {
                          NotesStatus.loading => MonitoringLoading(
                            label: text.fmNotesLoading,
                          ),
                          NotesStatus.failure => MonitoringError(
                            message: isAccessFailure(state.errorCode)
                                ? text.fmErrorAccess
                                : text.fmErrorUnknown,
                            onRetry: isAccessFailure(state.errorCode)
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
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  text.fmNotesEmptyMessage,
                                  style: const TextStyle(
                                    color: TataColors.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          NotesStatus.ready => Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                text.fmNotesSection,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 10),
                              for (final note in state.notes) ...[
                                MonitoringCard(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(note.text),
                                      const SizedBox(height: 6),
                                      Text(
                                        text.fmNotesMeta(
                                          text.fmNotesAuthorYou,
                                          monitoringDateTime(
                                            locale,
                                            note.recordedAt,
                                          ),
                                        ),
                                        style: const TextStyle(
                                          color: TataColors.muted,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                              ],
                            ],
                          ),
                        },
                        const SizedBox(height: 8),
                        MonitoringCard(
                          color: TataColors.infoSurface,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                text.fmNotesSharedHistory,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(text.fmNotesSharedHistoryBody),
                            ],
                          ),
                        ),
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
