import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/application/time/clock.dart';
import '../../../../shared/presentation/widgets/caregiver_tab_bar.dart';
import '../bloc/history/history_bloc.dart';
import '../bloc/history/history_event.dart';
import '../bloc/history/history_state.dart';
import '../screens/adherence_history_screen.dart';
import '../widgets/adherence_labels.dart';

/// Owns the [HistoryBloc] of one adult and wires the screen to its callbacks.
///
/// The caller decides where "Ver recomendaciones" and each bottom tab lead; a
/// credential that is no longer valid is reported through
/// [onSessionInvalidated] instead of being shown as a screen error.
class AdherenceHistoryRoute extends StatefulWidget {
  const AdherenceHistoryRoute({
    super.key,
    required this.createBloc,
    required this.onOpenRecommendations,
    required this.onTabSelected,
    required this.onSessionInvalidated,
    this.clock = DateTime.now,
  });

  final HistoryBloc Function() createBloc;
  final VoidCallback onOpenRecommendations;
  final ValueChanged<CaregiverTab> onTabSelected;
  final VoidCallback onSessionInvalidated;
  final Clock clock;

  @override
  State<AdherenceHistoryRoute> createState() => _AdherenceHistoryRouteState();
}

class _AdherenceHistoryRouteState extends State<AdherenceHistoryRoute> {
  late final HistoryBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = widget.createBloc()..add(const HistoryRequested());
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BlocProvider.value(
    value: _bloc,
    child: BlocConsumer<HistoryBloc, HistoryState>(
      listenWhen: (previous, current) =>
          previous.errorCode != current.errorCode,
      listener: (context, state) {
        if (adherenceSessionLostCodes.contains(state.errorCode)) {
          widget.onSessionInvalidated();
        }
      },
      builder: (context, state) => AdherenceHistoryScreen(
        state: state,
        clock: widget.clock,
        onPeriodSelected: (period) => _bloc.add(HistoryPeriodSelected(period)),
        onOpenRecommendations: widget.onOpenRecommendations,
        onRetry: () => _bloc.add(const HistoryRequested()),
        onTabSelected: widget.onTabSelected,
      ),
    ),
  );
}
