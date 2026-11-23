import 'package:flutter/material.dart';

import '../../features/adherence_analytics/presentation/bloc/level/level_bloc.dart';
import '../../features/adherence_analytics/presentation/navigation/adherence_badge_view.dart';
import '../../features/adherence_analytics/presentation/navigation/treatment_adherence_view.dart';
import '../../features/treatment_management/presentation/navigation/treatment_navigation.dart';
import '../../shared/presentation/widgets/caregiver_tab_bar.dart';

/// Shared entry to review a followed person's treatment regimen and reminders.
/// Used by More and recommendations; writes occur only after the caregiver saves.
Future<void> openCaregiverTreatments(
  BuildContext context, {
  required String olderAdultId,
  required String personName,
  required TreatmentNavigation treatments,
  required VoidCallback onSessionInvalidated,
  LevelBloc Function(String olderAdultId)? createPersonAdherenceBloc,
  LevelBloc Function(String olderAdultId, String treatmentId)?
  createTreatmentAdherenceBloc,
}) {
  return treatments.openTreatments(
    context,
    olderAdultId,
    onSessionInvalidated,
    personName: personName,
    personBadgeBuilder: createPersonAdherenceBloc == null
        ? null
        : (invalidated) => AdherenceBadgeView(
            createBloc: () => createPersonAdherenceBloc(olderAdultId),
            onSessionInvalidated: invalidated,
          ),
    adherenceBuilder: createTreatmentAdherenceBloc == null
        ? null
        : (id, invalidated) => TreatmentAdherenceView(
            key: ValueKey('treatment-adherence-$id'),
            createBloc: () => createTreatmentAdherenceBloc(olderAdultId, id),
            onSessionInvalidated: invalidated,
          ),
    navigationBuilder: (detailContext) => CaregiverTabBar(
      selected: CaregiverTab.person,
      enabledTabs: const {CaregiverTab.home, CaregiverTab.person},
      onSelected: (tab) {
        final navigator = Navigator.of(detailContext);
        if (tab == CaregiverTab.home) {
          navigator.popUntil((route) => route.isFirst);
        } else if (tab == CaregiverTab.person) {
          final person = ModalRoute.of(context);
          navigator.popUntil((route) => route == person || route.isFirst);
        }
      },
    ),
  );
}
