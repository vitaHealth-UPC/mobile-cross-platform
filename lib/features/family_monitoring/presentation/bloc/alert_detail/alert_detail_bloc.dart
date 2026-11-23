import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../shared/common/result/app_result.dart';
import '../../../application/failure_codes.dart';
import '../../../application/ports/monitoring_ports.dart';
import '../../../application/readmodels/monitoring_readmodels.dart';
import '../../../application/usecases/alert_usecases.dart';
import '../../../domain/entities/caregiver_alert.dart';
import '../../../domain/value_objects/alert_status.dart';
import '../../texts/monitoring_texts.dart';

sealed class AlertDetailEvent {
  const AlertDetailEvent();
}

/// Load the alert and everything shown beside it.
final class AlertDetailRequested extends AlertDetailEvent {
  const AlertDetailRequested();
}

/// Refreshes protected evidence after returning from a contact app or the background.
final class AlertDetailResumed extends AlertDetailEvent {
  const AlertDetailResumed();
}

/// Read the contact again after it could not be read.
final class AlertContactRequested extends AlertDetailEvent {
  const AlertContactRequested();
}

/// Attend or close the alert.
final class AlertStatusChangeRequested extends AlertDetailEvent {
  const AlertStatusChangeRequested(this.target);
  final AlertStatus target;
}

/// Outcome of the last follow-up action on the alert.
sealed class AlertFeedback {
  const AlertFeedback();
}

final class AlertStatusChanged extends AlertFeedback {
  const AlertStatusChanged(this.status);
  final AlertStatus status;
}

final class AlertUpdateFailed extends AlertFeedback {
  const AlertUpdateFailed(this.code);
  final String code;
}

enum AlertDetailStatus { loading, ready, failure }

/// Contact offer of the alert detail (US-29); a missing channel is ready with a null channel.
final class AlertContactState {
  const AlertContactState({this.option, this.errorCode});
  final ContactOption? option;
  final String? errorCode;

  bool get loading => option == null && errorCode == null;
}

final class AlertDetailState {
  const AlertDetailState({
    this.status = AlertDetailStatus.loading,
    this.alert,
    this.dose,
    this.updating,
    this.feedback,
    this.errorCode,
    this.contact = const AlertContactState(),
    this.person,
    this.history,
  });

  final AlertDetailStatus status;
  final CaregiverAlert? alert;
  final MonitoredDose? dose;

  /// The status being sent, while a change is in flight.
  final AlertStatus? updating;
  final AlertFeedback? feedback;
  final String? errorCode;
  final AlertContactState contact;
  final MonitoredPerson? person;

  /// Steps the backend recorded; null while they are not known.
  final List<RecordedAlertEvent>? history;

  AlertDetailState copyWith({
    AlertDetailStatus? status,
    CaregiverAlert? alert,
    MonitoredDose? Function()? dose,
    AlertStatus? Function()? updating,
    AlertFeedback? Function()? feedback,
    String? Function()? errorCode,
    AlertContactState? contact,
    MonitoredPerson? Function()? person,
    List<RecordedAlertEvent>? Function()? history,
  }) => AlertDetailState(
    status: status ?? this.status,
    alert: alert ?? this.alert,
    dose: dose == null ? this.dose : dose(),
    updating: updating == null ? this.updating : updating(),
    feedback: feedback == null ? this.feedback : feedback(),
    errorCode: errorCode == null ? this.errorCode : errorCode(),
    contact: contact ?? this.contact,
    person: person == null ? this.person : person(),
    history: history == null ? this.history : history(),
  );
}

/// Loads one alert, its contact, person, dose and recorded steps, and serializes the status
/// mutations against refreshes. Losing access invalidates every protected part at once.
final class AlertDetailBloc extends Bloc<AlertDetailEvent, AlertDetailState> {
  AlertDetailBloc({
    required this._detail,
    required this._update,
    required this._contact,
    required this._people,
    required this._doses,
    required this._history,
    required this.olderAdultId,
    required this.alertId,
  }) : super(const AlertDetailState()) {
    on<AlertDetailRequested>(_requested);
    on<AlertDetailResumed>(_resumed);
    on<AlertContactRequested>((event, emit) => _loadContact(emit));
    on<AlertStatusChangeRequested>(_change);
  }

  final GetAlertDetail _detail;
  final UpdateAlertStatus _update;
  final ContactOptionReader _contact;
  final MonitoredPersonReader _people;
  final MonitoredDoseReader _doses;
  final AlertHistoryReader _history;
  final String olderAdultId;
  final int alertId;

  int _alertRevision = 0;
  int _contactRevision = 0;
  int _personRevision = 0;
  int _historyRevision = 0;

  bool get _denied =>
      state.status == AlertDetailStatus.failure &&
      isAccessFailure(state.errorCode);

  Future<void> _requested(
    AlertDetailRequested event,
    Emitter<AlertDetailState> emit,
  ) async {
    if (state.updating != null) return;
    await Future.wait([
      _loadAlert(emit),
      _loadContact(emit),
      _loadPerson(emit),
      _loadHistory(emit),
    ]);
  }

  Future<void> _resumed(
    AlertDetailResumed event,
    Emitter<AlertDetailState> emit,
  ) => _requested(const AlertDetailRequested(), emit);

  Future<void> _loadAlert(Emitter<AlertDetailState> emit) async {
    final revision = ++_alertRevision;
    emit(
      AlertDetailState(
        contact: state.contact,
        person: state.person,
        history: state.history,
      ),
    );
    final result = await _detail(olderAdultId, alertId);
    if (revision != _alertRevision || emit.isDone) return;
    switch (result) {
      case AppSuccess(:final value):
        final doseResult = await _doses.read(olderAdultId, value.intakeId);
        if (revision != _alertRevision || emit.isDone) return;
        if (doseResult case AppFailure(:final code)
            when isAccessFailure(code)) {
          _deny(emit, code);
          return;
        }
        emit(
          state.copyWith(
            status: AlertDetailStatus.ready,
            alert: value,
            dose: () => switch (doseResult) {
              AppSuccess(:final value) => value,
              AppFailure() => null,
            },
          ),
        );
      case AppFailure(:final code):
        if (isAccessFailure(code)) {
          _deny(emit, code);
        } else {
          emit(
            AlertDetailState(
              status: AlertDetailStatus.failure,
              errorCode: code,
              contact: state.contact,
              person: state.person,
              history: state.history,
            ),
          );
        }
    }
  }

  Future<void> _loadContact(Emitter<AlertDetailState> emit) async {
    if (_denied) return;
    final revision = ++_contactRevision;
    emit(state.copyWith(contact: const AlertContactState()));
    final result = await _contact(olderAdultId);
    if (revision != _contactRevision || emit.isDone) return;
    switch (result) {
      case AppSuccess(:final value):
        emit(state.copyWith(contact: AlertContactState(option: value)));
      case AppFailure(:final code):
        if (isAccessFailure(code)) {
          _deny(emit, code);
        } else {
          emit(state.copyWith(contact: AlertContactState(errorCode: code)));
        }
    }
  }

  Future<void> _loadPerson(Emitter<AlertDetailState> emit) async {
    if (_denied) return;
    final revision = ++_personRevision;
    emit(state.copyWith(person: () => null));
    final result = await _people.read(olderAdultId);
    if (revision != _personRevision || emit.isDone) return;
    switch (result) {
      case AppSuccess(:final value):
        emit(state.copyWith(person: () => value));
      case AppFailure(:final code):
        if (isAccessFailure(code)) _deny(emit, code);
    }
  }

  Future<void> _loadHistory(Emitter<AlertDetailState> emit) async {
    if (_denied) return;
    final revision = ++_historyRevision;
    emit(state.copyWith(history: () => null));
    final result = await _history.read(olderAdultId, alertId);
    if (revision != _historyRevision || emit.isDone) return;
    switch (result) {
      case AppSuccess(:final value):
        emit(state.copyWith(history: () => value));
      case AppFailure(:final code):
        if (isAccessFailure(code)) _deny(emit, code);
    }
  }

  /// A move already in flight or one the alert cannot make is ignored.
  Future<void> _change(
    AlertStatusChangeRequested event,
    Emitter<AlertDetailState> emit,
  ) async {
    final current = state.alert;
    if (state.status != AlertDetailStatus.ready ||
        current == null ||
        state.updating != null ||
        !current.status.canMoveTo(event.target)) {
      return;
    }
    emit(state.copyWith(updating: () => event.target, feedback: () => null));
    final result = await _update(olderAdultId, alertId, event.target);
    if (emit.isDone) return;
    switch (result) {
      case AppSuccess(:final value):
        emit(
          state.copyWith(
            alert: value,
            updating: () => null,
            feedback: () => AlertStatusChanged(value.status),
          ),
        );
        await _loadHistory(emit);
      case AppFailure(:final code):
        await _afterFailedUpdate(emit, code);
    }
  }

  /// On a 409 the alert moved elsewhere: show its current state instead of the stale one.
  Future<void> _afterFailedUpdate(
    Emitter<AlertDetailState> emit,
    String code,
  ) async {
    if (isAccessFailure(code)) {
      _deny(emit, code);
      return;
    }
    final failed = AlertUpdateFailed(code);
    if (code != MonitoringFailureCodes.statusConflict) {
      emit(state.copyWith(updating: () => null, feedback: () => failed));
      return;
    }
    final fresh = await _detail(olderAdultId, alertId);
    if (emit.isDone) return;
    switch (fresh) {
      case AppSuccess(:final value):
        emit(
          state.copyWith(
            alert: value,
            updating: () => null,
            feedback: () => failed,
            dose: () => state.dose?.id == value.intakeId ? state.dose : null,
          ),
        );
      case AppFailure(:final code) when isAccessFailure(code):
        _deny(emit, code);
      case AppFailure():
        emit(state.copyWith(updating: () => null, feedback: () => failed));
    }
  }

  /// Access failure invalidates every protected subflow of this detail.
  void _deny(Emitter<AlertDetailState> emit, String code) {
    _alertRevision++;
    _contactRevision++;
    _personRevision++;
    _historyRevision++;
    emit(
      AlertDetailState(
        status: AlertDetailStatus.failure,
        errorCode: code,
        contact: AlertContactState(errorCode: code),
      ),
    );
  }
}
