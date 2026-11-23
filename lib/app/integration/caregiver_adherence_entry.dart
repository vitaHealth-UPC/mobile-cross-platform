import 'package:flutter/material.dart';

import '../../features/adherence_analytics/presentation/bloc/history/history_bloc.dart';
import '../../features/adherence_analytics/presentation/bloc/recommendations/recommendations_bloc.dart';
import '../../features/adherence_analytics/presentation/navigation/adherence_flow_route.dart';
import '../../features/care_link/application/readmodels/caregiver_link_summary.dart';

/// Opens the adherence history of the person of [link] on top of the caregiver
/// area, reading with the caregiver's own session.
///
/// Care Link only hands over the confirmed relationship and Adherence Analytics
/// only receives the adult identifier, so neither context knows the other.
/// It is what the "Historial" action of the Family Summary opens.
///
/// Every bottom tab returns to the caregiver area, which owns the
/// destinations the tabs lead to. A credential the server rejects
/// closes the flow and is reported through [onSessionInvalidated].
Future<void> openAdherenceFlow(
  BuildContext context, {
  required CaregiverLinkSummary link,
  required HistoryBloc Function(String olderAdultId) createHistoryBloc,
  required RecommendationsBloc Function(String olderAdultId)
  createRecommendationsBloc,
  required VoidCallback onSessionInvalidated,
}) {
  final navigator = Navigator.of(context);
  void backToCaregiverArea() => navigator.popUntil((route) => route.isFirst);
  return navigator.push<void>(
    MaterialPageRoute(
      builder: (_) => AdherenceFlowRoute(
        olderAdultId: link.olderAdultId,
        createHistoryBloc: createHistoryBloc,
        createRecommendationsBloc: createRecommendationsBloc,
        onTabSelected: (_) => backToCaregiverArea(),
        onSessionInvalidated: () {
          backToCaregiverArea();
          onSessionInvalidated();
        },
      ),
    ),
  );
}
