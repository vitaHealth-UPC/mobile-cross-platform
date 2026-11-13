import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/presentation/theme/tata_colors.dart';
import '../../../../shared/presentation/widgets/caregiver_tab_bar.dart';
import '../../application/readmodels/monitoring_readmodels.dart';
import '../../domain/entities/caregiver_alert.dart';
import '../../domain/value_objects/alert_status.dart';
import '../bloc/alerts/alerts_bloc.dart';
import '../texts/monitoring_texts.dart';
import '../widgets/monitoring_widgets.dart';

/// Alerts of the followed person with the doses of the day, filterable by status.
class AlertsScreen extends StatefulWidget {
  const AlertsScreen({
    super.key,
    required this.onTab,
    required this.onOpenAlert,
    this.onOpenSummary,
    this.tickEvery = const Duration(minutes: 1),
  });

  final ValueChanged<CaregiverTab> onTab;
  final ValueChanged<CaregiverAlert> onOpenAlert;
  final VoidCallback? onOpenSummary;

  /// How often the "in N min" labels advance without rereading the backend.
  final Duration tickEvery;

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen>
    with WidgetsBindingObserver {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _timer = Timer.periodic(
      widget.tickEvery,
      (_) => context.read<AlertsBloc>().add(AlertsClockTicked(DateTime.now())),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<AlertsBloc>().add(const AlertsRequested());
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: TataColors.background,
      extendBody: true,
      bottomNavigationBar: DefaultTextStyle.merge(
        style: const TextStyle(letterSpacing: 0, height: 1.2),
        child: CaregiverTabBar(
          selected: CaregiverTab.alerts,
          onSelected: widget.onTab,
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: BlocBuilder<AlertsBloc, AlertsState>(
          builder: (context, state) => RefreshIndicator(
            onRefresh: () async =>
                context.read<AlertsBloc>().add(const AlertsRequested()),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                22,
                22,
                22,
                MediaQuery.paddingOf(context).bottom + 110,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MonitoringHeader(
                    title: text.fmAlertsTitle,
                    subtitle: text.fmAlertsSubtitle,
                  ),
                  const SizedBox(height: 16),
                  _Filters(selected: state.filter),
                  const SizedBox(height: 14),
                  _Body(
                    state: state,
                    onOpenAlert: widget.onOpenAlert,
                    onOpenSummary: widget.onOpenSummary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Filters extends StatelessWidget {
  const _Filters({required this.selected});
  final AlertFilter selected;

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    final labels = {
      AlertFilter.all: text.fmFilterAll,
      AlertFilter.pending: text.fmFilterPending,
      AlertFilter.upcoming: text.fmFilterUpcoming,
      AlertFilter.completed: text.fmFilterCompleted,
    };
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final filter in AlertFilter.values)
          MonitoringFilterChip(
            label: labels[filter]!,
            selected: filter == selected,
            onTap: () =>
                context.read<AlertsBloc>().add(AlertsFilterSelected(filter)),
          ),
      ],
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.state,
    required this.onOpenAlert,
    this.onOpenSummary,
  });

  final AlertsState state;
  final ValueChanged<CaregiverAlert> onOpenAlert;
  final VoidCallback? onOpenSummary;

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    switch (state.status) {
      case AlertsStatus.loading:
        return MonitoringLoading(label: text.fmAlertsLoading);
      case AlertsStatus.failure:
        return MonitoringError(
          message: monitoringErrorText(text, state.errorCode),
          onRetry: isAccessFailure(state.errorCode)
              ? null
              : () => context.read<AlertsBloc>().add(const AlertsRequested()),
        );
      case AlertsStatus.empty:
        return MonitoringCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                text.fmAlertsEmptyTitle,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                text.fmAlertsEmptyMessage,
                style: const TextStyle(color: TataColors.muted),
              ),
            ],
          ),
        );
      case AlertsStatus.ready:
        final alerts = state.visibleAlerts;
        final doses = state.visibleDoses;
        if (alerts.isEmpty && doses.isEmpty) {
          return Text(
            text.fmAlertsFilterEmpty,
            style: const TextStyle(color: TataColors.muted),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              state.pendingCount == 0
                  ? text.fmNoPending
                  : text.fmPendingSummary(state.pendingCount),
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: TataColors.muted,
              ),
            ),
            const SizedBox(height: 10),
            for (final alert in alerts) ...[
              _AlertCard(alert: alert, onTap: () => onOpenAlert(alert)),
              const SizedBox(height: 12),
            ],
            for (final dose in doses) ...[
              _DoseCard(
                dose: dose,
                now: state.asOf ?? DateTime.now(),
                onTap: onOpenSummary,
              ),
              const SizedBox(height: 12),
            ],
          ],
        );
    }
  }
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({required this.alert, required this.onTap});
  final CaregiverAlert alert;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final open = alert.status == AlertStatus.open;
    return Semantics(
      button: true,
      label: text.fmOpenDetail,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: MonitoringCard(
          color: open ? TataColors.errorSurface : Colors.white,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alertStatusTitle(text, alert.status),
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: open ? TataColors.errorText : TataColors.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(alert.medicationName),
                    Text(
                      text.fmAlertScheduled(
                        monitoringTime(locale, alert.scheduledAt),
                      ),
                      style: const TextStyle(color: TataColors.muted),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: TataColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}

class _DoseCard extends StatelessWidget {
  const _DoseCard({required this.dose, required this.now, this.onTap});
  final MonitoredDose dose;
  final DateTime now;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final title = switch (dose.status) {
      'CONFIRMED' => text.fmDoseConfirmed,
      'LATE' => text.fmDoseLate,
      _ => text.fmDoseUpcoming,
    };
    final minutes = dose.scheduledAt.difference(now).inMinutes;
    final subtitle = dose.isDone
        ? text.fmConfirmedBadge
        : minutes < 60
        ? text.fmDueMinutes(minutes < 1 ? 1 : minutes)
        : text.fmDueHoursMinutes(minutes ~/ 60, minutes % 60);
    return Semantics(
      button: onTap != null,
      label: text.fmViewDose,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: MonitoringCard(
          color: dose.isDone ? TataColors.mint : TataColors.lavender,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(
                text.fmTimelinePerson(
                  monitoringTime(locale, dose.scheduledAt),
                  dose.medicationName,
                ),
              ),
              Text(subtitle, style: const TextStyle(color: TataColors.muted)),
            ],
          ),
        ),
      ),
    );
  }
}
