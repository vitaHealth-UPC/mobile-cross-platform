import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/presentation/theme/tata_colors.dart';
import '../../../../shared/presentation/widgets/caregiver_tab_bar.dart';
import '../../../../shared/presentation/widgets/initials_avatar.dart';
import '../../application/ports/contact_launcher.dart';
import '../../domain/entities/notes.dart';
import '../../domain/value_objects/contact_channel.dart';
import '../bloc/notes/notes_bloc.dart';
import '../bloc/summary/family_summary_bloc.dart';
import '../texts/monitoring_texts.dart';
import '../widgets/monitoring_widgets.dart';
import 'family_summary_screen.dart' show showFamilyContact;

/// Figma 563:1121, Linked Person: who the followed adult is, how the link
/// stands, their adherence and treatment, quick actions and the latest note.
/// Profile and notes come from [NotesBloc], contact from [FamilySummaryBloc];
/// the adherence and treatment cards are composed by the host.
class LinkedPersonScreen extends StatelessWidget {
  const LinkedPersonScreen({
    super.key,
    required this.olderAdultName,
    required this.linkedSince,
    required this.launcher,
    required this.onBack,
    required this.onTab,
    required this.onOpenMedications,
    required this.onOpenHistory,
    this.adherence,
    this.treatment,
    this.now = DateTime.now,
    this.onEdit,
  });

  final String olderAdultName;

  /// When the adult consented to the link.
  final DateTime linkedSince;
  final ContactLauncher launcher;

  /// Returns to the list of followed people.
  final VoidCallback onBack;
  final ValueChanged<CaregiverTab> onTab;
  final VoidCallback onOpenMedications;
  final VoidCallback onOpenHistory;
  final Widget? adherence;
  final Widget? treatment;
  final DateTime Function() now;
  final VoidCallback? onEdit;

  static const _muted = Color(0xFF5B6475);

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    return Scaffold(
      backgroundColor: TataColors.background,
      extendBody: true,
      bottomNavigationBar: DefaultTextStyle.merge(
        style: const TextStyle(letterSpacing: 0, height: 1.2),
        child: CaregiverTabBar(
          selected: CaregiverTab.person,
          onSelected: onTab,
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: BlocListener<FamilySummaryBloc, FamilySummaryState>(
          listenWhen: (a, b) => a.contact == null && b.contact != null,
          listener: (context, _) => showFamilyContact(context, launcher),
          child: BlocBuilder<NotesBloc, NotesState>(
            builder: (context, notes) {
              if (notes.status == NotesStatus.failure) {
                return Padding(
                  padding: const EdgeInsets.all(22),
                  child: MonitoringError(
                    message: monitoringErrorText(text, notes.errorCode),
                    onRetry: () =>
                        context.read<NotesBloc>().add(const NotesRequested()),
                  ),
                );
              }
              if (notes.status == NotesStatus.loading) {
                return MonitoringLoading(label: text.fmSummaryLoading);
              }
              final person = notes.person;
              final name = person?.fullName ?? olderAdultName;
              final age = person?.ageAt(now());
              final born = person?.birthDate;
              return RefreshIndicator(
                onRefresh: () async =>
                    context.read<NotesBloc>().add(const NotesRequested()),
                child: ListView(
                  padding: EdgeInsets.fromLTRB(
                    22,
                    16,
                    22,
                    MediaQuery.paddingOf(context).bottom + 110,
                  ),
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: onBack,
                          tooltip: text.back,
                          icon: const Icon(
                            Icons.arrow_back_ios_new,
                            size: 20,
                            color: TataColors.ink,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Semantics(
                            header: true,
                            child: Text(
                              name,
                              style: const TextStyle(
                                fontFamily: 'DMSerifDisplay',
                                fontSize: 28,
                                height: 1.15,
                                color: TataColors.ink,
                              ),
                            ),
                          ),
                        ),
                        if (onEdit != null)
                          TextButton(
                            onPressed: onEdit,
                            child: Text(text.tmEdit),
                          ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Avatar(name: name),
                        const SizedBox(width: 22),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (age != null)
                                Text(
                                  text.lpAge(age),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: TataColors.ink,
                                  ),
                                ),
                              if (born != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  text.lpBirthday(
                                    DateFormat('d MMM', locale).format(born),
                                  ),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: _muted,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE5F3E8),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  text.lpLinked,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF2E6B46),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                text.lpLinkedSince(
                                  DateFormat(
                                    'MMM yyyy',
                                    locale,
                                  ).format(linkedSince.toLocal()),
                                ),
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: _muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (adherence case final card?) ...[
                      const SizedBox(height: 20),
                      card,
                    ],
                    if (treatment case final card?) ...[
                      const SizedBox(height: 18),
                      card,
                    ],
                    const SizedBox(height: 20),
                    _QuickActions(
                      onCall: () => context.read<FamilySummaryBloc>().add(
                        const FamilyContactRequested(
                          channelType: ContactChannelType.phone,
                        ),
                      ),
                      onMessage: () => context.read<FamilySummaryBloc>().add(
                        const FamilyContactRequested(
                          channelType: ContactChannelType.whatsapp,
                        ),
                      ),
                      onMedications: onOpenMedications,
                      onHistory: onOpenHistory,
                    ),
                    const SizedBox(height: 16),
                    _LatestNote(
                      state: notes,
                      onOpenNotes: () => onTab(CaregiverTab.notes),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    final initials = InitialsAvatar.initialsOf(name);
    return ExcludeSemantics(
      child: Container(
        width: 92,
        height: 92,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [Color(0xFFEDE7FB), Color(0xFFD9CFF6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Color(0x1A173B70),
              blurRadius: 14,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Text(
          initials,
          style: const TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w600,
            color: TataColors.primary,
          ),
        ),
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({
    required this.onCall,
    required this.onMessage,
    required this.onMedications,
    required this.onHistory,
  });

  final VoidCallback onCall;
  final VoidCallback onMessage;
  final VoidCallback onMedications;
  final VoidCallback onHistory;

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    final actions = [
      ('person_call', text.lpCall, const Color(0xFFE4F3E8), onCall),
      ('person_message', text.lpMessages, const Color(0xFFEDE7FB), onMessage),
      (
        'person_medication',
        text.lpMedications,
        const Color(0xFFFFEBD8),
        onMedications,
      ),
      ('person_history', text.lpHistory, const Color(0xFFE2EEF8), onHistory),
    ];
    return Row(
      children: [
        for (final (index, (icon, label, color, onTap)) in actions.indexed) ...[
          if (index > 0) const SizedBox(width: 8),
          Expanded(
            child: Material(
              color: color,
              borderRadius: BorderRadius.circular(18),
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(18),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 76),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 10,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SvgPicture.asset(
                          'assets/icons/$icon.svg',
                          width: 24,
                          height: 24,
                          excludeFromSemantics: true,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          label,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 12,
                            height: 1.2,
                            color: TataColors.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _LatestNote extends StatelessWidget {
  const _LatestNote({required this.state, required this.onOpenNotes});
  final NotesState state;
  final VoidCallback onOpenNotes;

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    FollowUpNote? latest;
    for (final note in state.notes) {
      if (latest == null || note.recordedAt.isAfter(latest.recordedAt)) {
        latest = note;
      }
    }
    final body = switch (state.status) {
      NotesStatus.loading => text.lpNoteLoading,
      NotesStatus.failure => text.lpNoteError,
      _ => latest?.text ?? text.lpNoteEmpty,
    };
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onOpenNotes,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 12, 12, 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14173B70),
                blurRadius: 16,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      text.lpNotesTitle,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: TataColors.ink,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      body,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.35,
                        color: TataColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
              Tooltip(
                message: text.lpOpenNotes,
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(
                    Icons.edit_outlined,
                    size: 18,
                    color: Color(0xFF5B6475),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
