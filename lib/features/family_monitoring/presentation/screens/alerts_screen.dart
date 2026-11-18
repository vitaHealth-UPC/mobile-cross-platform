import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/presentation/theme/tata_colors.dart';
import '../../../../shared/presentation/widgets/caregiver_tab_bar.dart';
import '../../application/readmodels/monitoring_readmodels.dart';
import '../../domain/entities/caregiver_alert.dart';
import '../../domain/value_objects/alert_severity.dart';
import '../../domain/value_objects/alert_status.dart';
import '../bloc/alerts/alerts_bloc.dart';
import '../texts/monitoring_texts.dart';
import '../widgets/alert_timeline_card.dart';
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

  /// How often the visible foreground view rereads alerts, priority and dose evidence.
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
    _configureTimer(
      WidgetsBinding.instance.lifecycleState ?? AppLifecycleState.resumed,
    );
  }

  void _configureTimer(AppLifecycleState state) {
    _timer?.cancel();
    _timer = null;
    if (state != AppLifecycleState.resumed) return;
    _timer = Timer.periodic(widget.tickEvery, (_) {
      if (!mounted || ModalRoute.of(context)?.isCurrent != true) return;
      final bloc = context.read<AlertsBloc>();
      if (!isAccessFailure(bloc.state.errorCode)) {
        bloc.add(const AlertsRequested(background: true));
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _configureTimer(state);
    if (state == AppLifecycleState.resumed &&
        ModalRoute.of(context)?.isCurrent == true) {
      final bloc = context.read<AlertsBloc>();
      if (!isAccessFailure(bloc.state.errorCode)) {
        bloc.add(const AlertsRequested());
      }
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
          builder: (context, state) => Stack(
            fit: StackFit.expand,
            children: [
              const Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white,
                        TataColors.background,
                        Color(0xFFFCFBFF),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: -9,
                right: 0,
                child: IgnorePointer(
                  child: Image.asset(
                    'assets/illustrations/alerts_glow.png',
                    width: 291,
                    height: 376,
                    excludeFromSemantics: true,
                  ),
                ),
              ),
              RefreshIndicator(
                onRefresh: () async {
                  final bloc = context.read<AlertsBloc>();
                  final done = bloc.stream.firstWhere(
                    (value) => value.status != AlertsStatus.loading,
                    orElse: () =>
                        const AlertsState(status: AlertsStatus.failure),
                  );
                  bloc.add(const AlertsRequested());
                  await done;
                },
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
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: MonitoringHeader(
                              title: text.fmAlertsTitle,
                              subtitle: state.day == null
                                  ? text.fmAlertsSubtitle
                                  : text.fmAlertsTodayDate(
                                      DateFormat.MMMMd(
                                        Localizations.localeOf(context)
                                            .toLanguageTag(),
                                      ).format(state.day!),
                                    ),
                            ),
                          ),
                          IconButton(
                            tooltip: text.fmFilterPending,
                            onPressed: () => context.read<AlertsBloc>().add(
                              const AlertsFilterSelected(AlertFilter.pending),
                            ),
                            icon: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                SvgPicture.asset(
                                  'assets/icons/alerts_header.svg',
                                  width: 24,
                                  height: 24,
                                  excludeFromSemantics: true,
                                ),
                                if (state.pendingCount > 0)
                                  Positioned(
                                    top: -3,
                                    right: -3,
                                    child: SvgPicture.asset(
                                      'assets/icons/alerts_header_dot.svg',
                                      width: 6,
                                      height: 6,
                                      excludeFromSemantics: true,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      if (state.status == AlertsStatus.ready ||
                          state.status == AlertsStatus.empty) ...[
                        _PriorityBanner(state: state),
                        const SizedBox(height: 14),
                      ],
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
            ],
          ),
        ),
      ),
    );
  }
}

/// Displays server-classified follow-up priority without interpreting omission age.
class _PriorityBanner extends StatelessWidget {
  const _PriorityBanner({required this.state});
  final AlertsState state;

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    final String title;
    if (state.criticalCount > 0) {
      title = text.fmCriticalAlerts(state.criticalCount);
    } else if (state.severityKnown) {
      title = text.fmNoCriticalAlerts;
    } else {
      title = text.fmSeverityUnknownTitle;
    }
    final String body;
    if (!state.severityKnown) {
      body = text.fmSeverityUnknownBody;
    } else if (state.criticalCount > 0 || state.pendingCount > 0) {
      body = text.fmAlertsPendingBody;
    } else {
      body = text.fmAlertsClearBody;
    }
    return AlertsStatusBanner(
      requiresAttention: state.criticalCount > 0 || !state.severityKnown,
      title: title,
      body: body,
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns =
            MediaQuery.textScalerOf(context).scale(11) > 14 ||
                constraints.maxWidth < 330
            ? 2
            : 4;
        final width = (constraints.maxWidth - 8 * (columns - 1)) / columns;
        return Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            for (final filter in AlertFilter.values)
              SizedBox(
                width: width,
                child: Semantics(
                  selected: filter == selected,
                  child: TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: filter == selected
                          ? TataColors.primary
                          : const Color(0xFFF0F0F5),
                      foregroundColor: filter == selected
                          ? Colors.white
                          : const Color(0xFF5B6475),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 8,
                      ),
                      minimumSize: const Size(0, 40),
                      shape: const StadiumBorder(),
                    ),
                    onPressed: () => context.read<AlertsBloc>().add(
                      AlertsFilterSelected(filter),
                    ),
                    child: Text(
                      labels[filter]!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
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
        final doses = [...state.visibleDoses]
          ..sort((a, b) {
            final group = (a.isDone ? 1 : 0).compareTo(b.isDone ? 1 : 0);
            return group == 0 ? a.scheduledAt.compareTo(b.scheduledAt) : group;
          });
        if (alerts.isEmpty && doses.isEmpty) {
          return Text(
            text.fmAlertsFilterEmpty,
            style: const TextStyle(color: TataColors.muted),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final alert in alerts) ...[
              _AlertCard(
                alert: alert,
                personName: state.olderAdultName,
                now: state.asOf ?? DateTime.now(),
                onTap: () => onOpenAlert(alert),
              ),
              const SizedBox(height: 12),
            ],
            for (final dose in doses) ...[
              _DoseCard(
                dose: dose,
                personName: state.olderAdultName,
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

/// Styles recorded follow-up alerts independently from scheduled dose outcomes.
class _AlertCard extends StatelessWidget {
  const _AlertCard({
    required this.alert,
    required this.personName,
    required this.now,
    required this.onTap,
  });
  final CaregiverAlert alert;
  final String personName;
  final DateTime now;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    final open = alert.status == AlertStatus.open;
    return AlertTimelineCard(
      title: alertStatusTitle(text, alert.status),
      personAndTime: text.fmTimelinePerson(
        _time(context, alert.scheduledAt),
        personName,
      ),
      medicationName: alert.medicationName,
      asset: open ? 'alerts_warning' : 'alerts_confirmed',
      colors: open
          ? const [Color(0xFFFFF0E8), Color(0xFFFBE0D1)]
          : const [Color(0xFFEAF5FB), Color(0xFFDDECF7)],
      caption: open ? _elapsed(text, now.difference(alert.scheduledAt)) : null,
      badge: alert.severity == AlertSeverity.critical
          ? text.fmSeverityCritical
          : alert.severity == AlertSeverity.high
          ? text.fmSeverityHigh
          : null,
      attentionBadge:
          alert.severity == AlertSeverity.critical ||
          alert.severity == AlertSeverity.high,
      onTap: onTap,
    );
  }
}

class _DoseCard extends StatelessWidget {
  const _DoseCard({
    required this.dose,
    required this.personName,
    required this.now,
    this.onTap,
  });
  final MonitoredDose dose;
  final String personName;
  final DateTime now;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    final upcoming = dose.status == 'PENDING' && dose.scheduledAt.isAfter(now);
    final title = switch (dose.status) {
      'CONFIRMED' => text.fmDoseConfirmed,
      'LATE' => text.fmDoseLate,
      'OMITTED' => text.fmDoseOmitted,
      _ => upcoming ? text.fmDoseUpcoming : text.fmDosePending,
    };
    String? caption;
    if (dose.status == 'PENDING') {
      if (upcoming) {
        final minutes = dose.scheduledAt.difference(now).inMinutes;
        caption = minutes < 60
            ? text.fmDueMinutes(minutes < 1 ? 1 : minutes)
            : text.fmDueHoursMinutes(minutes ~/ 60, minutes % 60);
      } else {
        caption = _elapsed(text, now.difference(dose.scheduledAt));
      }
    }
    final String timeLabel;
    final recorded = dose.confirmedAt;
    if (dose.isDone && recorded != null) {
      timeLabel = _time(context, recorded);
    } else if (dose.isDone) {
      timeLabel = text.fmAlertScheduled(_time(context, dose.scheduledAt));
    } else {
      timeLabel = _time(context, dose.scheduledAt);
    }
    return AlertTimelineCard(
      title: title,
      personAndTime: text.fmTimelinePerson(timeLabel, personName),
      medicationName: dose.medicationName,
      asset: dose.isDone
          ? 'alerts_confirmed'
          : upcoming
          ? 'alerts_reminder'
          : 'alerts_warning',
      colors: dose.isDone
          ? const [Color(0xFFEAF5FB), Color(0xFFDDECF7)]
          : upcoming
          ? const [Color(0xFFF1ECFF), Color(0xFFE7DFFC)]
          : const [Color(0xFFFFF0E8), Color(0xFFFBE0D1)],
      caption: caption,
      badge: dose.status == 'CONFIRMED' ? text.fmConfirmedBadge : null,
      onTap: () => showDialog<void>(
        context: context,
        builder: (dialog) => AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(personName),
              const SizedBox(height: 12),
              Text(dose.medicationName),
              Text(dose.dose),
              Text(_time(context, dose.scheduledAt)),
            ],
          ),
          actions: [
            if (onTap != null)
              TextButton(
                onPressed: () {
                  Navigator.of(dialog).pop();
                  onTap!();
                },
                child: Text(text.fmPersonSummary),
              ),
            TextButton(
              onPressed: () => Navigator.of(dialog).pop(),
              child: Text(MaterialLocalizations.of(dialog).closeButtonLabel),
            ),
          ],
        ),
      ),
    );
  }
}

String _time(BuildContext context, DateTime at) => DateFormat(
  'h:mm a',
  Localizations.localeOf(context).toLanguageTag(),
).format(at.toLocal());

String _elapsed(AppLocalizations text, Duration duration) {
  final minutes = duration.inMinutes < 0 ? 0 : duration.inMinutes;
  if (minutes >= 1440) {
    return text.fmElapsedDaysHours(minutes ~/ 1440, (minutes % 1440) ~/ 60);
  }
  return minutes < 60
      ? text.fmElapsedMinutes(minutes)
      : text.fmElapsedHoursMinutes(minutes ~/ 60, minutes % 60);
}
