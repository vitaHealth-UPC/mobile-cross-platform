import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/presentation/theme/tata_colors.dart';
import '../../../../shared/presentation/widgets/caregiver_tab_bar.dart';
import '../../application/ports/contact_launcher.dart';
import '../../domain/value_objects/alert_severity.dart';
import '../../domain/value_objects/alert_status.dart';
import '../bloc/alert_detail/alert_detail_bloc.dart';
import '../bloc/notes/note_composer_cubit.dart';
import '../texts/monitoring_texts.dart';
import '../widgets/alert_detail_cards.dart';
import '../widgets/follow_up_note_dialog.dart';
import '../widgets/monitoring_widgets.dart';

/// Detail of one alert with the follow-up actions: contact, attend, close and add a note.
class AlertDetailScreen extends StatefulWidget {
  const AlertDetailScreen({
    super.key,
    required this.launcher,
    this.onBack,
    this.onOpenSummary,
    this.onOpenProfile,
    this.onTab,
  });

  final ContactLauncher launcher;
  final VoidCallback? onBack;
  final VoidCallback? onOpenSummary;
  final VoidCallback? onOpenProfile;
  final ValueChanged<CaregiverTab>? onTab;

  @override
  State<AlertDetailScreen> createState() => _AlertDetailScreenState();
}

class _AlertDetailScreenState extends State<AlertDetailScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<AlertDetailBloc>().add(const AlertDetailResumed());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    return BlocListener<NoteComposerCubit, NoteComposerState>(
      listenWhen: (a, b) => a.failureCode != b.failureCode,
      listener: (context, state) {
        final code = state.failureCode;
        if (code != null && isAccessFailure(code)) {
          context.read<AlertDetailBloc>().add(AlertDetailAccessLost(code));
          context.read<NoteComposerCubit>().clear();
        }
      },
      child: NoteComposerHost(
        showSavedMessage: false,
        child: Scaffold(
          backgroundColor: TataColors.background,
          bottomNavigationBar: widget.onTab == null
              ? null
              : CaregiverTabBar(
                  selected: CaregiverTab.alerts,
                  onSelected: widget.onTab!,
                ),
          body: SafeArea(
            child: BlocConsumer<AlertDetailBloc, AlertDetailState>(
              listenWhen: (a, b) =>
                  (a.feedback != b.feedback && b.feedback != null) ||
                  a.errorCode != b.errorCode,
              listener: (context, state) {
                if (isAccessFailure(state.errorCode)) {
                  context.read<NoteComposerCubit>().clear();
                }
                if (state.feedback != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(_feedback(text, state.feedback!))),
                  );
                }
              },
              builder: (context, state) => SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 8, 22, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        BackButton(
                          onPressed:
                              widget.onBack ??
                              () => Navigator.of(context).maybePop(),
                        ),
                        Expanded(
                          child: Text(
                            state.alert == null
                                ? text.fmDetailTitle
                                : alertStatusTitle(text, state.alert!.status),
                            style: const TextStyle(
                              fontFamily: 'DMSerifDisplay',
                              fontSize: 24,
                              color: TataColors.ink,
                            ),
                          ),
                        ),
                        if (state.alert != null &&
                            state.alert!.status != AlertStatus.closed)
                          PopupMenuButton<AlertStatus>(
                            tooltip: text.fmActionsTitle,
                            enabled: state.updating == null,
                            onSelected: (_) => _confirmAlertClose(
                              context,
                              context.read<AlertDetailBloc>(),
                            ),
                            itemBuilder: (_) => [
                              PopupMenuItem(
                                value: AlertStatus.closed,
                                child: Text(text.fmActionClose),
                              ),
                            ],
                          ),
                      ],
                    ),
                    if (state.alert != null)
                      Align(
                        alignment: Alignment.centerRight,
                        child: AlertDetailStatusPill(
                          status: state.alert!.status,
                        ),
                      ),
                    const SizedBox(height: 18),
                    switch (state.status) {
                      AlertDetailStatus.loading => MonitoringLoading(
                        label: text.fmDetailLoading,
                      ),
                      AlertDetailStatus.failure => MonitoringError(
                        message: monitoringErrorText(
                          text,
                          state.errorCode,
                          detail: true,
                        ),
                        onRetry: isAccessFailure(state.errorCode)
                            ? null
                            : () => context.read<AlertDetailBloc>().add(
                                const AlertDetailRequested(),
                              ),
                      ),
                      AlertDetailStatus.ready => _Ready(
                        state: state,
                        launcher: widget.launcher,
                        onOpenSummary: widget.onOpenSummary,
                        onOpenProfile: widget.onOpenProfile,
                      ),
                    },
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _feedback(AppLocalizations text, AlertFeedback feedback) =>
      switch (feedback) {
        AlertStatusChanged(:final status) =>
          status == AlertStatus.closed
              ? text.fmFeedbackClosed
              : text.fmFeedbackAttended,
        AlertUpdateFailed(:final code) =>
          code == 'ALERT_STATUS_CONFLICT'
              ? text.fmFeedbackConflict
              : text.fmFeedbackFailed,
      };
}

class _Ready extends StatelessWidget {
  const _Ready({
    required this.state,
    required this.launcher,
    this.onOpenSummary,
    this.onOpenProfile,
  });

  final AlertDetailState state;
  final ContactLauncher launcher;
  final VoidCallback? onOpenSummary;
  final VoidCallback? onOpenProfile;

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final alert = state.alert!;
    final person = state.person;
    final age = person?.ageAt(DateTime.now());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AlertMedicationHero(alert: alert, dose: state.dose),
        const SizedBox(height: 20),
        if (person != null) ...[
          MonitoringCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: TataColors.lavender,
                  child: Text(
                    person.fullName.trim().isEmpty
                        ? '?'
                        : person.fullName.trim().characters.first,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        person.fullName,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      if (age != null) Text(text.fmPersonAge(age)),
                    ],
                  ),
                ),
                if (onOpenProfile != null || onOpenSummary != null)
                  TextButton(
                    onPressed: onOpenProfile ?? onOpenSummary,
                    child: Text(
                      onOpenProfile != null
                          ? text.fmPersonProfile
                          : text.fmPersonSummary,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],
        if (state.history != null && state.history!.isNotEmpty) ...[
          AlertReminderTimeline(events: state.history!),
          const SizedBox(height: 20),
        ],
        _Actions(state: state, launcher: launcher),
        const SizedBox(height: 14),
        ExpansionTile(
          tilePadding: EdgeInsets.zero,
          title: Text(
            text.fmDetailSection,
            style: const TextStyle(fontSize: 14),
          ),
          children: [
            MonitoringCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    text.fmDetailSection,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  _Row(
                    text.fmDetailScheduled,
                    '${alert.medicationName}, '
                    '${monitoringDateTime(locale, alert.scheduledAt)}',
                  ),
                  _Row(
                    text.fmDetailReason,
                    alert.reason.trim().isEmpty
                        ? text.fmDetailReasonMissing
                        : alert.reason,
                  ),
                  _Row(
                    text.fmDetailStatus,
                    alertStatusLabel(text, alert.status),
                  ),
                  _Row(text.fmSeverityLabel, switch (alert.severity) {
                    AlertSeverity.standard => text.fmSeverityStandard,
                    AlertSeverity.high => text.fmSeverityHigh,
                    AlertSeverity.critical => text.fmSeverityCritical,
                    AlertSeverity.unknown => text.fmSeverityUnknownTitle,
                  }),
                  _Row(
                    text.fmDetailOpened,
                    monitoringDateTime(locale, alert.openedAt),
                  ),
                  if (alert.closedAt != null)
                    _Row(
                      text.fmDetailClosed,
                      monitoringDateTime(locale, alert.closedAt!),
                    ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 4,
          child: Text(label, style: const TextStyle(color: TataColors.muted)),
        ),
        Expanded(flex: 6, child: Text(value)),
      ],
    ),
  );
}

class _Actions extends StatelessWidget {
  const _Actions({required this.state, required this.launcher});

  final AlertDetailState state;
  final ContactLauncher launcher;

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    final bloc = context.read<AlertDetailBloc>();
    final alert = state.alert!;
    final busy = state.updating != null;
    final contact = state.contact;
    final firstName = contact.option?.firstName;
    return AlertDetailSurface(
      colors: const [Color(0xFFFFF5DF), Color(0xFFFBEAC9)],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            text.fmActionsTitle,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            firstName == null
                ? text.fmActionsSubtitle
                : text.fmActionsSubtitleNamed(firstName),
            style: const TextStyle(
              fontSize: 11,
              height: 1.4,
              color: Color(0xFF5B6475),
            ),
          ),
          const SizedBox(height: 12),
          if (contact.loading)
            Text(text.fmContactLoading)
          else if (contact.errorCode != null)
            TextButton(
              onPressed: () => bloc.add(const AlertContactRequested()),
              child: Text(text.fmContactRetry),
            )
          else if (contact.option?.channel == null)
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: null,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 48),
                  disabledBackgroundColor: const Color(0xFFEBEDF2),
                  disabledForegroundColor: const Color(0xFF575E6E),
                  shape: const StadiumBorder(),
                ),
                child: Text(text.fmContactUnavailable),
              ),
            )
          else
            ContactChannelView(
              option: contact.option!,
              launcher: launcher,
              actionLabel: firstName == null
                  ? text.fmContactAction
                  : text.fmContactActionNamed(firstName),
              showChannel: false,
            ),
          const SizedBox(height: 12),
          if (alert.status == AlertStatus.closed)
            Text(
              text.fmClosedNote,
              style: const TextStyle(color: TataColors.muted),
            )
          else ...[
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  backgroundColor: TataColors.lavender,
                  disabledBackgroundColor: alert.status == AlertStatus.attended
                      ? const Color(0xFFE5F4E8)
                      : TataColors.lavender,
                  disabledForegroundColor: alert.status == AlertStatus.attended
                      ? const Color(0xFF296B40)
                      : const Color(0xFF5B6475),
                  minimumSize: const Size(0, 48),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  side: BorderSide(
                    color: alert.status == AlertStatus.attended
                        ? const Color(0xFF95C4A3)
                        : const Color(0xFFCFC4ED),
                  ),
                  shape: const StadiumBorder(),
                ),
                onPressed: busy || alert.status == AlertStatus.attended
                    ? null
                    : () => bloc.add(
                        const AlertStatusChangeRequested(AlertStatus.attended),
                      ),
                child: Text(
                  state.updating == AlertStatus.attended
                      ? text.fmActionSaving
                      : alert.status == AlertStatus.attended
                      ? text.fmActionAttended
                      : text.fmActionAttend,
                ),
              ),
            ),
          ],
          const SizedBox(height: 10),
          const _FollowUpNoteAction(),
        ],
      ),
    );
  }
}

/// Keeps the acknowledged receipt visible without removing the next-note action.
class _FollowUpNoteAction extends StatelessWidget {
  const _FollowUpNoteAction();

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    final cubit = context.read<NoteComposerCubit>();
    return BlocBuilder<NoteComposerCubit, NoteComposerState>(
      builder: (context, state) {
        if (state.saved && state.note != null) {
          return Row(
            children: [
              Semantics(
                key: const Key('follow-up-note-saved'),
                liveRegion: true,
                child: Text(
                  text.fmNoteSaved,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2E754A),
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: cubit.open,
                tooltip: text.fmNoteAddFollowUp,
                icon: const Icon(Icons.add, size: 20),
              ),
            ],
          );
        }
        return TextButton(
          onPressed: state.saving ? null : cubit.open,
          child: Text(text.fmNoteAddFollowUp),
        );
      },
    );
  }
}

Future<void> _confirmAlertClose(
  BuildContext context,
  AlertDetailBloc bloc,
) async {
  final text = AppLocalizations.of(context);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialog) => AlertDialog(
      title: Text(text.fmCloseConfirmTitle),
      content: Text(text.fmCloseConfirmMessage),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialog).pop(false),
          child: Text(text.fmCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialog).pop(true),
          child: Text(text.fmActionClose),
        ),
      ],
    ),
  );
  if (confirmed == true && context.mounted && !bloc.isClosed) {
    bloc.add(const AlertStatusChangeRequested(AlertStatus.closed));
  }
}
