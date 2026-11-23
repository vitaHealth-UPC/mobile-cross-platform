import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/application/time/clock.dart';
import '../bloc/agenda/agenda_bloc.dart';
import '../bloc/agenda/agenda_event.dart';
import '../bloc/agenda/agenda_state.dart';
import '../screens/agenda_screen.dart';

/// Owns the [AgendaBloc] and reloads the week after a dose is opened, since a
/// confirmation there changes the statuses shown here.
class AgendaRoute extends StatefulWidget {
  const AgendaRoute({
    super.key,
    required this.createBloc,
    required this.onOpenDose,
    required this.onSessionInvalidated,
    this.clock = DateTime.now,
    this.onBack,
    this.onMore,
  });

  final AgendaBloc Function() createBloc;

  /// Opens one dose and completes when the user returns to the agenda.
  final Future<void> Function(String intakeId) onOpenDose;
  final VoidCallback onSessionInvalidated;
  final Clock clock;
  final VoidCallback? onBack;
  final VoidCallback? onMore;

  @override
  State<AgendaRoute> createState() => _AgendaRouteState();
}

class _AgendaRouteState extends State<AgendaRoute> {
  late final AgendaBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = widget.createBloc()..add(const AgendaRequested());
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  Future<void> _refresh() async {
    _bloc.add(const AgendaRequested());
    await _bloc.stream.firstWhere(
      (state) => state.status != AgendaStatus.loading,
    );
  }

  Future<void> _open(String intakeId) async {
    await widget.onOpenDose(intakeId);
    if (mounted) _bloc.add(const AgendaRequested());
  }

  @override
  Widget build(BuildContext context) => BlocProvider.value(
    value: _bloc,
    child: BlocConsumer<AgendaBloc, AgendaState>(
      listenWhen: (previous, current) =>
          previous.errorCode != current.errorCode,
      listener: (context, state) {
        if (const {
          'AUTHENTICATION_REQUIRED',
          'SESSION_CHANGED',
          'ACCESS_DENIED',
        }.contains(state.errorCode)) {
          widget.onSessionInvalidated();
        }
      },
      builder: (context, state) {
        final text = AppLocalizations.of(context);
        return AgendaScreen(
          state: state,
          today: widget.clock(),
          errorText: switch (state.errorCode) {
            null => null,
            'NETWORK_UNAVAILABLE' => text.networkUnavailable,
            'RATE_LIMITED' => text.rateLimited,
            _ => text.homeErrorBody,
          },
          onSelectDay: (day) => _bloc.add(AgendaDaySelected(day)),
          onMoveWeek: (weeks) => _bloc.add(AgendaWeekMoved(weeks)),
          onRetry: _refresh,
          onOpenDose: _open,
          onBack: widget.onBack,
          onMore: widget.onMore,
        );
      },
    ),
  );
}
