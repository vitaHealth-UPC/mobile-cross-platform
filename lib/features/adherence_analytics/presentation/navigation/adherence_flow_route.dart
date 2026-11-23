import 'package:flutter/material.dart';

import '../../../../shared/application/time/clock.dart';
import '../../../../shared/presentation/widgets/caregiver_tab_bar.dart';
import '../bloc/history/history_bloc.dart';
import '../bloc/recommendations/recommendations_bloc.dart';
import 'adherence_history_route.dart';
import 'adherence_recommendations_route.dart';

/// Entry of the adherence analytics flow for one older adult: the history
/// first and, on top of it, the recommendations.
///
/// The host composes the blocs and decides where each bottom tab leads, so the
/// flow works the same when Family Monitoring opens it from its summary.
class AdherenceFlowRoute extends StatelessWidget {
  const AdherenceFlowRoute({
    super.key,
    required this.olderAdultId,
    required this.createHistoryBloc,
    required this.createRecommendationsBloc,
    required this.onTabSelected,
    required this.onSessionInvalidated,
    this.onApplyAdjustments,
    this.clock = DateTime.now,
  });

  final String olderAdultId;
  final HistoryBloc Function(String olderAdultId) createHistoryBloc;
  final RecommendationsBloc Function(String olderAdultId)
  createRecommendationsBloc;
  final ValueChanged<CaregiverTab> onTabSelected;
  final VoidCallback onSessionInvalidated;

  /// Opens the host treatment review; the user chooses a treatment and saves
  /// any edits there. No regimen is changed automatically by analytics.
  final VoidCallback? onApplyAdjustments;
  final Clock clock;

  @override
  Widget build(BuildContext context) => AdherenceHistoryRoute(
    createBloc: () => createHistoryBloc(olderAdultId),
    clock: clock,
    onTabSelected: onTabSelected,
    onSessionInvalidated: onSessionInvalidated,
    onOpenRecommendations: () => Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (routeContext) => AdherenceRecommendationsRoute(
          createBloc: () => createRecommendationsBloc(olderAdultId),
          onBackToHistory: () => Navigator.of(routeContext).pop(),
          onTabSelected: onTabSelected,
          onSessionInvalidated: onSessionInvalidated,
          onApplyAdjustments: onApplyAdjustments,
        ),
      ),
    ),
  );
}
