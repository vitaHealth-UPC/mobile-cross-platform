import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/presentation/widgets/caregiver_tab_bar.dart';
import '../../application/ports/contact_launcher.dart';
import '../../application/readmodels/monitoring_readmodels.dart';
import '../bloc/alert_detail/alert_detail_bloc.dart';
import '../bloc/alerts/alerts_bloc.dart';
import '../bloc/notes/note_composer_cubit.dart';
import '../bloc/notes/notes_bloc.dart';
import '../bloc/personal_notes/personal_notes_bloc.dart';
import '../bloc/summary/family_summary_bloc.dart';
import '../screens/alert_detail_screen.dart';
import '../screens/alerts_screen.dart';
import '../screens/family_summary_screen.dart';
import '../screens/followed_agenda_sheet.dart';
import '../screens/linked_person_screen.dart';
import '../screens/notes_screen.dart';
import '../screens/personal_notes_screen.dart';
import '../texts/monitoring_texts.dart';

/// Builders for the blocs of the Family Monitoring flows.
/// What the host adds to the Person tab (Figma 563:1121): the link date and
/// the cards that belong to other contexts.
final class LinkedPersonSlots {
  const LinkedPersonSlots({
    required this.linkedSince,
    this.adherence,
    this.treatment,
    this.onEdit,
  });

  final DateTime linkedSince;
  final WidgetBuilder? adherence;
  final WidgetBuilder? treatment;

  /// Returns the server-acknowledged name, or null when editing is cancelled.
  final Future<String?> Function(BuildContext)? onEdit;
}

final class FamilyMonitoringFactories {
  const FamilyMonitoringFactories({
    required this.launcher,
    required this.createSummaryBloc,
    required this.createAlertsBloc,
    required this.createAlertDetailBloc,
    required this.createNotesBloc,
    required this.createComposerCubit,
    required this.createPersonalNotesBloc,
  });

  final ContactLauncher launcher;
  final FamilySummaryBloc Function(String olderAdultId, String olderAdultName)
  createSummaryBloc;
  final AlertsBloc Function(String olderAdultId) createAlertsBloc;
  final AlertDetailBloc Function(String olderAdultId, int alertId)
  createAlertDetailBloc;
  final NotesBloc Function(String olderAdultId) createNotesBloc;
  final NoteComposerCubit Function(String olderAdultId) createComposerCubit;
  final PersonalNotesBloc Function() createPersonalNotesBloc;
}

/// Opens the monitoring area of the caregiver and the older adult's own notes.
final class FamilyMonitoringNavigation {
  const FamilyMonitoringNavigation(this._factories);
  final FamilyMonitoringFactories _factories;

  /// Caregiver home of one followed person. The shell owns the Home/Alerts/Notes tabs and,
  /// with [person], the Person tab, whose back arrow calls [onPerson]; without [person]
  /// the Person tab calls [onPerson] directly. The More tab is decided by [onMore].
  /// The summary is read again when [onAddMedication], [onOpenStock] or [onMore]
  /// completes, because medications or stock may have changed there.
  Widget caregiverHome({
    required String olderAdultId,
    required String olderAdultName,
    required VoidCallback onHistory,
    required FutureOr<void> Function() onAddMedication,
    required VoidCallback onPerson,
    required FutureOr<void> Function() onMore,
    required VoidCallback onSessionInvalidated,
    FutureOr<void> Function(StockAttention stock)? onOpenStock,
    LinkedPersonSlots? person,
  }) => _CaregiverShell(
    factories: _factories,
    olderAdultId: olderAdultId,
    olderAdultName: olderAdultName,
    onHistory: onHistory,
    onAddMedication: onAddMedication,
    onPerson: onPerson,
    onMore: onMore,
    onSessionInvalidated: onSessionInvalidated,
    onOpenStock: onOpenStock,
    person: person,
  );

  /// The older adult's own notes, loaded when the screen appears.
  Widget personalNotes({
    VoidCallback? onHome,
    VoidCallback? onMedications,
    VoidCallback? onAgenda,
    VoidCallback? onMore,
    required VoidCallback onSignIn,
  }) => BlocProvider(
    create: (_) =>
        _factories.createPersonalNotesBloc()
          ..add(const PersonalNotesRequested()),
    child: PersonalNotesScreen(
      onHome: onHome,
      onMedications: onMedications,
      onAgenda: onAgenda,
      onMore: onMore,
      onSignIn: onSignIn,
    ),
  );
}

class _CaregiverShell extends StatefulWidget {
  const _CaregiverShell({
    required this.factories,
    required this.olderAdultId,
    required this.olderAdultName,
    required this.onHistory,
    required this.onAddMedication,
    required this.onPerson,
    required this.onMore,
    required this.onSessionInvalidated,
    this.onOpenStock,
    this.person,
  });

  final FamilyMonitoringFactories factories;
  final String olderAdultId;
  final String olderAdultName;
  final VoidCallback onHistory;
  final FutureOr<void> Function() onAddMedication;
  final VoidCallback onPerson;
  final FutureOr<void> Function() onMore;
  final VoidCallback onSessionInvalidated;
  final FutureOr<void> Function(StockAttention stock)? onOpenStock;
  final LinkedPersonSlots? person;

  @override
  State<_CaregiverShell> createState() => _CaregiverShellState();
}

class _CaregiverShellState extends State<_CaregiverShell> {
  CaregiverTab _tab = CaregiverTab.home;
  int _personRevision = 0;

  Future<void> _editPerson() async {
    final name = await widget.person?.onEdit?.call(context);
    if (!mounted || name == null) return;
    _summary.add(FamilySummaryNameUpdated(name));
    _notes.add(const NotesRequested());
    setState(() => _personRevision++);
  }

  late final FamilySummaryBloc _summary;
  late final AlertsBloc _alerts;
  late final NotesBloc _notes;
  late final NoteComposerCubit _composer;

  @override
  void initState() {
    super.initState();
    final f = widget.factories;
    _summary = f.createSummaryBloc(widget.olderAdultId, widget.olderAdultName)
      ..add(const FamilySummaryRequested());
    _alerts = f.createAlertsBloc(widget.olderAdultId)
      ..add(const AlertsRequested());
    _notes = f.createNotesBloc(widget.olderAdultId)
      ..add(const NotesRequested());
    _composer = f.createComposerCubit(widget.olderAdultId);
  }

  @override
  void dispose() {
    _summary.close();
    _alerts.close();
    _notes.close();
    _composer.close();
    super.dispose();
  }

  void _select(CaregiverTab tab) {
    switch (tab) {
      case CaregiverTab.person when widget.person == null:
        widget.onPerson();
      case CaregiverTab.person:
        if (tab != _tab) {
          _notes.add(const NotesRequested());
          setState(() => _tab = tab);
        }
      case CaregiverTab.more:
        _thenRefresh(widget.onMore);
      case CaregiverTab.home || CaregiverTab.alerts || CaregiverTab.notes:
        // A tab that opens is refreshed: the data may have changed meanwhile.
        if (tab != _tab) {
          switch (tab) {
            case CaregiverTab.alerts:
              _alerts.add(const AlertsRequested());
            case CaregiverTab.notes:
              _notes.add(const NotesRequested());
            default:
              _summary.add(const FamilySummaryRequested());
          }
          setState(() => _tab = tab);
        }
    }
  }

  /// Shows every dose of today with the caregiver's read-only authorization.
  Future<void> _openAgenda() async {
    _alerts.add(const AlertsRequested());
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.8,
        child: BlocProvider.value(
          value: _alerts,
          child: const FollowedAgendaSheet(),
        ),
      ),
    );
  }

  /// Runs a host flow that may change medications or stock, then reads the summary again.
  Future<void> _thenRefresh(FutureOr<void> Function() open) async {
    await open();
    if (mounted) _summary.add(const FamilySummaryRequested());
  }

  void _openDetail(int alertId) {
    final f = widget.factories;
    Navigator.of(context)
        .push<void>(
          MaterialPageRoute(
            builder: (_) => MultiBlocProvider(
              providers: [
                BlocProvider(
                  create: (_) =>
                      f.createAlertDetailBloc(widget.olderAdultId, alertId)
                        ..add(const AlertDetailRequested()),
                ),
                BlocProvider(
                  create: (_) => f.createComposerCubit(widget.olderAdultId),
                ),
              ],
              child: Builder(
                builder: (detailContext) =>
                    BlocListener<AlertDetailBloc, AlertDetailState>(
                      listenWhen: (a, b) => a.errorCode != b.errorCode,
                      listener: (_, state) {
                        if (state.errorCode == 'ACCESS_DENIED') {
                          _summary.add(
                            const FamilySummaryAccessLost('ACCESS_DENIED'),
                          );
                        }
                        if (isSessionFailure(state.errorCode)) {
                          Navigator.of(detailContext)
                              .popUntil((r) => r.isFirst);
                          widget.onSessionInvalidated();
                        }
                      },
                      child: AlertDetailScreen(
                        launcher: f.launcher,
                        onTab: (tab) {
                          Navigator.of(detailContext).pop();
                          _select(tab);
                        },
                        onOpenProfile: () {
                          Navigator.of(detailContext).pop();
                          _select(CaregiverTab.person);
                        },
                        onOpenSummary: () {
                          Navigator.of(detailContext).pop();
                          _select(CaregiverTab.home);
                        },
                      ),
                    ),
              ),
            ),
          ),
        )
        .then((_) {
          // The status may have changed in the detail.
          if (mounted) {
            _alerts.add(const AlertsRequested());
            _summary.add(const FamilySummaryRequested());
          }
        });
  }

  @override
  Widget build(BuildContext context) => MultiBlocProvider(
    providers: [
      BlocProvider.value(value: _summary),
      BlocProvider.value(value: _alerts),
      BlocProvider.value(value: _notes),
      BlocProvider.value(value: _composer),
    ],
    child: MultiBlocListener(
      listeners: [
        BlocListener<FamilySummaryBloc, FamilySummaryState>(
          listenWhen: (a, b) => a.errorCode != b.errorCode,
          listener: (_, state) {
            if (state.errorCode == 'ACCESS_DENIED') {
              _notes.add(NotesAccessLost(state.errorCode!));
              _composer.clear();
            }
            if (isSessionFailure(state.errorCode)) {
              widget.onSessionInvalidated();
            }
          },
        ),
        BlocListener<AlertsBloc, AlertsState>(
          listenWhen: (a, b) => a.errorCode != b.errorCode,
          listener: (_, state) {
            if (state.errorCode == 'ACCESS_DENIED') {
              _summary.add(const FamilySummaryAccessLost('ACCESS_DENIED'));
            }
            if (isSessionFailure(state.errorCode)) {
              widget.onSessionInvalidated();
            }
          },
        ),
        BlocListener<NotesBloc, NotesState>(
          listenWhen: (a, b) => a.errorCode != b.errorCode,
          listener: (_, state) {
            if (state.errorCode == 'ACCESS_DENIED') {
              _summary.add(const FamilySummaryAccessLost('ACCESS_DENIED'));
            }
            if (isSessionFailure(state.errorCode)) {
              widget.onSessionInvalidated();
            }
          },
        ),
      ],
      child: switch (_tab) {
        CaregiverTab.alerts => AlertsScreen(
          onTab: _select,
          onOpenAlert: (alert) => _openDetail(alert.id),
          onOpenSummary: () => _select(CaregiverTab.home),
        ),
        CaregiverTab.notes => NotesScreen(onTab: _select),
        CaregiverTab.person when widget.person != null => LinkedPersonScreen(
          olderAdultName: widget.olderAdultName,
          linkedSince: widget.person!.linkedSince,
          launcher: widget.factories.launcher,
          onBack: widget.onPerson,
          onTab: _select,
          onOpenMedications: () => _thenRefresh(widget.onAddMedication),
          onOpenHistory: widget.onHistory,
          onEdit: widget.person!.onEdit == null ? null : _editPerson,
          adherence: KeyedSubtree(
            key: ValueKey('adherence-$_personRevision'),
            child:
                widget.person!.adherence?.call(context) ??
                const SizedBox.shrink(),
          ),
          treatment: KeyedSubtree(
            key: ValueKey('treatment-$_personRevision'),
            child:
                widget.person!.treatment?.call(context) ??
                const SizedBox.shrink(),
          ),
        ),
        _ => FamilySummaryScreen(
          launcher: widget.factories.launcher,
          onTab: _select,
          onHistory: widget.onHistory,
          onOpenAgenda: _openAgenda,
          onChoosePerson: widget.onPerson,
          onAddMedication: () => _thenRefresh(widget.onAddMedication),
          onOpenAlerts: () => _select(CaregiverTab.alerts),
          onOpenStock: switch (widget.onOpenStock) {
            final open? => (stock) => _thenRefresh(() => open(stock)),
            null => null,
          },
        ),
      },
    ),
  );
}
