import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/presentation/theme/tata_colors.dart';
import '../../application/ports/contact_launcher.dart';
import '../../application/readmodels/monitoring_readmodels.dart';
import '../../domain/value_objects/alert_status.dart';
import '../bloc/alert_detail/alert_detail_bloc.dart';
import '../bloc/notes/note_composer_cubit.dart';
import '../texts/monitoring_texts.dart';
import '../widgets/follow_up_note_dialog.dart';
import '../widgets/monitoring_widgets.dart';

/// Detail of one alert with the follow-up actions: contact, attend, close and add a note.
class AlertDetailScreen extends StatefulWidget {
  const AlertDetailScreen({
    super.key,
    required this.launcher,
    this.onBack,
    this.onOpenSummary,
  });

  final ContactLauncher launcher;
  final VoidCallback? onBack;
  final VoidCallback? onOpenSummary;

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
    return NoteComposerHost(
      child: Scaffold(
        backgroundColor: TataColors.background,
        appBar: AppBar(
          backgroundColor: TataColors.background,
          elevation: 0,
          leading: BackButton(
            onPressed: widget.onBack ?? () => Navigator.of(context).maybePop(),
          ),
          title: Text(text.fmDetailTitle),
        ),
        body: SafeArea(
          child: BlocConsumer<AlertDetailBloc, AlertDetailState>(
            listenWhen: (a, b) =>
                a.feedback != b.feedback && b.feedback != null,
            listener: (context, state) => ScaffoldMessenger.of(context)
                .showSnackBar(
                  SnackBar(content: Text(_feedback(text, state.feedback!))),
                ),
            builder: (context, state) => SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 8, 22, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                    ),
                  },
                ],
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
  });

  final AlertDetailState state;
  final ContactLauncher launcher;
  final VoidCallback? onOpenSummary;

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
        MonitoringHeader(title: alertStatusTitle(text, alert.status)),
        const SizedBox(height: 14),
        if (person != null) ...[
          MonitoringCard(
            color: TataColors.lavender,
            child: Row(
              children: [
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
                if (onOpenSummary != null)
                  TextButton(
                    onPressed: onOpenSummary,
                    child: Text(text.fmPersonSummary),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],
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
                '${alert.medicationName} · '
                '${monitoringDateTime(locale, alert.scheduledAt)}',
              ),
              _Row(
                text.fmDetailReason,
                alert.reason.trim().isEmpty
                    ? text.fmDetailReasonMissing
                    : alert.reason,
              ),
              _Row(text.fmDetailStatus, alertStatusLabel(text, alert.status)),
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
        const SizedBox(height: 14),
        if (state.history != null && state.history!.isNotEmpty) ...[
          _Events(events: state.history!, locale: locale),
          const SizedBox(height: 14),
        ],
        _Actions(state: state, launcher: launcher, person: person),
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

class _Events extends StatelessWidget {
  const _Events({required this.events, required this.locale});
  final List<RecordedAlertEvent> events;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    String label(RecordedAlertEventType type) => switch (type) {
      RecordedAlertEventType.intakeScheduled => text.fmEventScheduled,
      RecordedAlertEventType.reinforcedReminderSent => text.fmEventReinforced,
      RecordedAlertEventType.alertGenerated => text.fmEventOpened,
      RecordedAlertEventType.alertClosed => text.fmEventClosed,
    };
    return MonitoringCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            text.fmEventsTitle,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          for (final event in events)
            _Row(
              label(event.type),
              monitoringDateTime(locale, event.occurredAt),
            ),
        ],
      ),
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({
    required this.state,
    required this.launcher,
    required this.person,
  });

  final AlertDetailState state;
  final ContactLauncher launcher;
  final MonitoredPerson? person;

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    final bloc = context.read<AlertDetailBloc>();
    final alert = state.alert!;
    final busy = state.updating != null;
    final contact = state.contact;
    final firstName = contact.option?.firstName;
    return MonitoringCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            text.fmActionsTitle,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            firstName == null
                ? text.fmActionsSubtitle
                : text.fmActionsSubtitleNamed(firstName),
            style: const TextStyle(color: TataColors.muted),
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
            Text(text.fmContactUnavailable)
          else
            ContactChannelView(option: contact.option!, launcher: launcher),
          const SizedBox(height: 12),
          if (alert.status == AlertStatus.closed)
            Text(
              text.fmClosedNote,
              style: const TextStyle(color: TataColors.muted),
            )
          else ...[
            MonitoringPrimaryButton(
              label: state.updating == AlertStatus.attended
                  ? text.fmActionSaving
                  : alert.status == AlertStatus.attended
                  ? text.fmActionAttended
                  : text.fmActionAttend,
              onPressed: busy || alert.status == AlertStatus.attended
                  ? null
                  : () => bloc.add(
                      const AlertStatusChangeRequested(AlertStatus.attended),
                    ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                onPressed: busy ? null : () => _confirmClose(context, bloc),
                child: Text(
                  state.updating == AlertStatus.closed
                      ? text.fmActionSaving
                      : text.fmActionClose,
                ),
              ),
            ),
          ],
          const SizedBox(height: 10),
          TextButton(
            onPressed: () => context.read<NoteComposerCubit>().open(),
            child: Text(text.fmNoteAddFollowUp),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmClose(BuildContext context, AlertDetailBloc bloc) async {
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
    if (confirmed == true) {
      bloc.add(const AlertStatusChangeRequested(AlertStatus.closed));
    }
  }
}
