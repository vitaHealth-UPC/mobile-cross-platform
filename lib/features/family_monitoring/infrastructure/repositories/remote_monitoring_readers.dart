import '../../../../shared/application/session/session_store.dart';
import '../../../../shared/common/result/app_result.dart';
import '../../application/ports/monitoring_ports.dart';
import '../../application/readmodels/monitoring_readmodels.dart';
import '../mappers/monitoring_mapper.dart';
import '../remote/family_monitoring_api.dart';
import 'monitoring_requests.dart';
import 'remote_family_monitoring_repository.dart';

/// Reads one protected timeline; a failed source never becomes a misleading empty section.
final class RemoteAlertTimelineReader implements AlertTimelineReader {
  const RemoteAlertTimelineReader({required this._api, required this._store});
  final FamilyMonitoringApi _api;
  final SessionStore _store;

  @override
  Future<AppResult<AlertTimeline>> read(
    String olderAdultId,
    DateTime day,
  ) async {
    final reads = CaregiverReads(_store);
    final StatusReading status;
    switch (await reads.read(
      (session) =>
          _api.status(olderAdultId, session.owner.id, session.accessToken),
      (response) => AppSuccess(MonitoringMapper.status(response.body)),
    )) {
      case AppSuccess(:final value):
        status = value;
      case AppFailure(:final code):
        return AppFailure(code);
    }
    final bounds = dayBounds(day);
    final List<MonitoredDose> doses;
    switch (await reads.read<List<MonitoredDose>>(
      (session) => _api.agenda(
        olderAdultId,
        bounds.from,
        bounds.to,
        session.accessToken,
      ),
      (response) {
        final doses = MonitoringMapper.doses(response.body);
        final inDay = doses.every((dose) {
          final local = dose.scheduledAt.toLocal();
          return local.year == day.year &&
              local.month == day.month &&
              local.day == day.day;
        });
        return inDay ? AppSuccess(doses) : const AppFailure('INVALID_RESPONSE');
      },
    )) {
      case AppSuccess(:final value):
        doses = value;
      case AppFailure(:final code):
        return AppFailure(code);
    }
    final MonitoredPerson person;
    switch (await reads.read<MonitoredPerson>(
      (session) => _api.profile(olderAdultId, session.accessToken),
      (response) {
        final person = MonitoringMapper.person(response.body);
        return person.id == olderAdultId
            ? AppSuccess(person)
            : const AppFailure('INVALID_RESPONSE');
      },
    )) {
      case AppSuccess(:final value):
        person = value;
      case AppFailure(:final code):
        return AppFailure(code);
    }
    return AppSuccess(
      AlertTimeline(
        alerts: status.openAlerts,
        doses: List.unmodifiable(
          [...doses]..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt)),
        ),
        olderAdultName: person.fullName,
        day: day,
      ),
    );
  }
}

/// Steps the backend recorded for an alert: it must at least say when the intake was
/// scheduled and when the alert was generated.
final class RemoteAlertHistoryReader implements AlertHistoryReader {
  const RemoteAlertHistoryReader({required this._api, required this._store});
  final FamilyMonitoringApi _api;
  final SessionStore _store;

  @override
  Future<AppResult<List<RecordedAlertEvent>>> read(
    String olderAdultId,
    int alertId,
  ) => caregiverMonitoringRequest(
    _store,
    (session) => _api.alertTimeline(
      olderAdultId,
      alertId,
      session.owner.id,
      session.accessToken,
    ),
    (response, _) {
      final events = MonitoringMapper.alertEvents(response.body);
      final types = events.map((event) => event.type).toSet();
      if (!types.contains(RecordedAlertEventType.intakeScheduled) ||
          !types.contains(RecordedAlertEventType.alertGenerated)) {
        return const AppFailure('INVALID_RESPONSE');
      }
      return AppSuccess(
        List.unmodifiable(
          [...events]..sort((a, b) => a.occurredAt.compareTo(b.occurredAt)),
        ),
      );
    },
  );
}

/// The intake behind an alert, checked to belong to the person being followed.
final class RemoteMonitoredDoseReader implements MonitoredDoseReader {
  const RemoteMonitoredDoseReader({required this._api, required this._store});
  final FamilyMonitoringApi _api;
  final SessionStore _store;

  @override
  Future<AppResult<MonitoredDose>> read(String olderAdultId, String intakeId) =>
      caregiverMonitoringRequest(
        _store,
        (session) => _api.intake(intakeId, session.accessToken),
        (response, _) {
          final reading = MonitoringMapper.dose(response.body);
          return reading.dose.id == intakeId &&
                  reading.olderAdultId == olderAdultId
              ? AppSuccess(reading.dose)
              : const AppFailure('INVALID_RESPONSE');
        },
      );
}

/// Authorized profile of the person being followed.
final class RemoteMonitoredPersonReader implements MonitoredPersonReader {
  const RemoteMonitoredPersonReader({required this._api, required this._store});
  final FamilyMonitoringApi _api;
  final SessionStore _store;

  @override
  Future<AppResult<MonitoredPerson>> read(String olderAdultId) =>
      caregiverMonitoringRequest(
        _store,
        (session) => _api.profile(olderAdultId, session.accessToken),
        (response, _) {
          final person = MonitoringMapper.person(response.body);
          return person.id == olderAdultId
              ? AppSuccess(person)
              : const AppFailure('INVALID_RESPONSE');
        },
      );
}
