import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/presentation/widgets/caregiver_tab_bar.dart';
import '../bloc/recommendations/recommendations_bloc.dart';
import '../bloc/recommendations/recommendations_event.dart';
import '../bloc/recommendations/recommendations_state.dart';
import '../screens/adherence_recommendations_screen.dart';
import '../widgets/adherence_labels.dart';

/// Owns the [RecommendationsBloc] of one adult and wires the screen.
///
/// [onApplyAdjustments] is optional: until a treatment flow can receive the
/// adjustments, the "Aplicar ajustes" button is not drawn. A credential that is
/// no longer valid is reported through [onSessionInvalidated].
class AdherenceRecommendationsRoute extends StatefulWidget {
  const AdherenceRecommendationsRoute({
    super.key,
    required this.createBloc,
    required this.onBackToHistory,
    required this.onTabSelected,
    required this.onSessionInvalidated,
    this.onApplyAdjustments,
  });

  final RecommendationsBloc Function() createBloc;
  final VoidCallback onBackToHistory;
  final ValueChanged<CaregiverTab> onTabSelected;
  final VoidCallback onSessionInvalidated;
  final VoidCallback? onApplyAdjustments;

  @override
  State<AdherenceRecommendationsRoute> createState() =>
      _AdherenceRecommendationsRouteState();
}

class _AdherenceRecommendationsRouteState
    extends State<AdherenceRecommendationsRoute> {
  late final RecommendationsBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = widget.createBloc()..add(const RecommendationsRequested());
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BlocProvider.value(
    value: _bloc,
    child: BlocConsumer<RecommendationsBloc, RecommendationsState>(
      listenWhen: (previous, current) =>
          previous.errorCode != current.errorCode,
      listener: (context, state) {
        if (adherenceSessionLostCodes.contains(state.errorCode)) {
          widget.onSessionInvalidated();
        }
      },
      builder: (context, state) => AdherenceRecommendationsScreen(
        state: state,
        onBackToHistory: widget.onBackToHistory,
        onRetry: () => _bloc.add(const RecommendationsRequested()),
        onTabSelected: widget.onTabSelected,
        onApplyAdjustments: widget.onApplyAdjustments,
      ),
    ),
  );
}
