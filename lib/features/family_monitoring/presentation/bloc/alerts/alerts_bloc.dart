import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../shared/application/time/clock.dart';
import '../../../../../shared/common/result/app_result.dart';
import '../../../application/readmodels/monitoring_readmodels.dart';
import '../../../application/usecases/alert_usecases.dart';
import '../../../domain/entities/caregiver_alert.dart';
import '../../../domain/value_objects/alert_status.dart';

/// Filters follow-up alerts and scheduled dose events without conflating their statuses.
enum AlertFilter {
  all({AlertStatus.open, AlertStatus.attended, AlertStatus.closed}),
  pending({AlertStatus.open}),
  upcoming({}),
  completed({AlertStatus.attended, AlertStatus.closed});

  const AlertFilter(this.statuses);
  final Set<AlertStatus> statuses;
}

sealed class AlertsEvent {
  const AlertsEvent();
}

/// Load or reload the alerts and the day's doses; also sent when the screen resumes.
final class AlertsRequested extends AlertsEvent {
  const AlertsRequested();
}

final class AlertsFilterSelected extends AlertsEvent {
  const AlertsFilterSelected(this.filter);
  final AlertFilter filter;
}

/// Advances presentation time without rereading unchanged protected data every minute.
final class AlertsClockTicked extends AlertsEvent {
  const AlertsClockTicked(this.now);
  final DateTime now;
}

enum AlertsStatus { loading, ready, empty, failure }

final class AlertsState {
  const AlertsState({
    this.status = AlertsStatus.loading,
    this.filter = AlertFilter.all,
    this.alerts = const [],
    this.doses = const [],
    this.olderAdultName = '',
    this.day,
    this.asOf,
    this.errorCode,
  });

  final AlertsStatus status;
  final AlertFilter filter;
  final List<CaregiverAlert> alerts;
  final List<MonitoredDose> doses;
  final String olderAdultName;

  /// Calendar day the doses belong to, in the device zone.
  final DateTime? day;

  /// Instant "upcoming" is measured from.
  final DateTime? asOf;
  final String? errorCode;

  AlertsState copyWith({
    AlertsStatus? status,
    AlertFilter? filter,
    DateTime? asOf,
  }) => AlertsState(
    status: status ?? this.status,
    filter: filter ?? this.filter,
    alerts: alerts,
    doses: doses,
    olderAdultName: olderAdultName,
    day: day,
    asOf: asOf ?? this.asOf,
    errorCode: errorCode,
  );

  List<CaregiverAlert> get visibleAlerts =>
      alerts.where((a) => filter.statuses.contains(a.status)).toList();

  List<MonitoredDose> get visibleDoses => _visibleDoses(filter);

  List<MonitoredDose> _visibleDoses(AlertFilter filter) {
    final now = asOf;
    bool upcoming(MonitoredDose d) =>
        d.status == 'PENDING' && now != null && d.scheduledAt.isAfter(now);
    return doses.where((dose) {
      return switch (filter) {
        AlertFilter.pending => false,
        AlertFilter.upcoming => upcoming(dose),
        AlertFilter.completed => dose.isDone,
        AlertFilter.all => upcoming(dose) || dose.isDone,
      };
    }).toList();
  }

  /// Whether nothing at all would be listed without a filter.
  bool get hasNothingToShow =>
      alerts.isEmpty && _visibleDoses(AlertFilter.all).isEmpty;

  int get pendingCount =>
      alerts.where((a) => a.status == AlertStatus.open).length;
}

/// Alerts of one adult with the doses of the day. A reload over visible content keeps it on
/// screen instead of flashing the loading state, and only the latest load may emit.
final class AlertsBloc extends Bloc<AlertsEvent, AlertsState> {
  AlertsBloc({
    required this._timeline,
    required this.olderAdultId,
    Clock? clock,
  }) : _clock = clock ?? DateTime.now,
       super(const AlertsState()) {
    on<AlertsRequested>(_load);
    on<AlertsFilterSelected>(
      (event, emit) => emit(state.copyWith(filter: event.filter)),
    );
    on<AlertsClockTicked>(_tick);
  }

  final GetAlertTimeline _timeline;
  final String olderAdultId;
  final Clock _clock;
  int _revision = 0;

  static DateTime _day(DateTime instant) {
    final local = instant.toLocal();
    return DateTime(local.year, local.month, local.day);
  }

  Future<void> _load(AlertsRequested event, Emitter<AlertsState> emit) async {
    final revision = ++_revision;
    final hasContent =
        state.status == AlertsStatus.ready ||
        state.status == AlertsStatus.empty;
    if (!hasContent) emit(const AlertsState());
    final now = _clock();
    final result = await _timeline(olderAdultId, _day(now));
    if (revision != _revision || emit.isDone) return;
    switch (result) {
      case AppSuccess(:final value):
        final next = AlertsState(
          filter: state.filter,
          alerts: value.alerts,
          doses: value.doses,
          olderAdultName: value.olderAdultName,
          day: value.day,
          asOf: now,
        );
        emit(
          next.copyWith(
            status: next.hasNothingToShow
                ? AlertsStatus.empty
                : AlertsStatus.ready,
          ),
        );
      case AppFailure(:final code):
        emit(AlertsState(status: AlertsStatus.failure, errorCode: code));
    }
  }

  void _tick(AlertsClockTicked event, Emitter<AlertsState> emit) {
    final day = state.day;
    if (state.status != AlertsStatus.ready &&
        state.status != AlertsStatus.empty) {
      return;
    }
    if (day != null && _day(event.now) != day) {
      add(const AlertsRequested());
    } else {
      emit(state.copyWith(asOf: event.now));
    }
  }
}
