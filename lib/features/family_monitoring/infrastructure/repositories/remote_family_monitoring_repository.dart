import '../../../../shared/application/session/session_store.dart';
import '../../../../shared/common/result/app_result.dart';
import '../../application/failure_codes.dart';
import '../../application/ports/monitoring_ports.dart';
import '../../application/readmodels/monitoring_readmodels.dart';
import '../../domain/value_objects/adherence_counts.dart';
import '../mappers/monitoring_mapper.dart';
import '../remote/family_monitoring_api.dart';
import 'monitoring_requests.dart';

/// Calendar-day bounds of the device zone as the instants the agenda endpoint expects.
({DateTime from, DateTime to}) dayBounds(DateTime day) => (
  from: DateTime(day.year, day.month, day.day),
  to: DateTime(day.year, day.month, day.day + 1),
);

bool _sameDay(DateTime instant, DateTime day) {
  final local = instant.toLocal();
  return local.year == day.year &&
      local.month == day.month &&
      local.day == day.day;
}

/// Aggregates protected monitoring evidence while telling optional connectivity failures
/// apart from the ones that must stop the summary.
final class RemoteFamilyMonitoringRepository
    implements FamilyMonitoringRepository {
  const RemoteFamilyMonitoringRepository({
    required this._api,
    required this._store,
  });
  final FamilyMonitoringApi _api;
  final SessionStore _store;

  @override
  Future<AppResult<FamilySummary>> summary(
    String olderAdultId,
    String name,
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
        return doses.every((dose) => _sameDay(dose.scheduledAt, day))
            ? AppSuccess(doses)
            : const AppFailure('INVALID_RESPONSE');
      },
    )) {
      case AppSuccess(:final value):
        doses = value;
      case AppFailure(:final code):
        return AppFailure(code);
    }

    final MonitoredDose? next;
    switch (await reads.read(
      (session) => _api.nextIntake(olderAdultId, session.accessToken),
      (response) => isEmptySuccess(response)
          ? const AppSuccess<MonitoredDose?>(null)
          : AppSuccess(MonitoringMapper.dose(response.body).dose),
    )) {
      case AppSuccess(:final value):
        next = value;
      case AppFailure(:final code):
        return AppFailure(code);
    }

    final stock = <StockAttention>[];
    var inventoryAvailable = true;
    final medications = <String, String>{
      for (final dose in [...doses, ?next])
        dose.medicationId: dose.medicationName,
    };
    for (final entry in medications.entries) {
      final result = await reads.read<StockReading>(
        (session) => _api.inventory(entry.key, session.accessToken),
        (response) {
          final reading = MonitoringMapper.inventory(response.body);
          return reading.medicationId == entry.key
              ? AppSuccess(reading)
              : const AppFailure('INVALID_RESPONSE');
        },
      );
      switch (result) {
        case AppSuccess(:final value):
          if (value.low) {
            stock.add(
              StockAttention(
                medicationId: value.medicationId,
                medicationName: entry.value,
                remaining: value.remaining,
              ),
            );
          }
        case AppFailure(:final code):
          if (accessLostCodes.contains(code)) return AppFailure(code);
          // A medication without an inventory record has no stock to report; any other
          // failure means the stock could not be checked, which the screen must not hide.
          if (code != MonitoringFailureCodes.notFound) {
            inventoryAvailable = false;
          }
      }
    }

    return AppSuccess(
      FamilySummary(
        olderAdultName: name,
        date: day,
        weekly: status.weekly,
        today: AdherenceCounts(
          doses.where((d) => d.isDone).length,
          doses.length,
        ),
        nextDose: next,
        stockAttention: List.unmodifiable(stock),
        openAlerts: List.unmodifiable([
          for (final alert in status.openAlerts)
            OpenAlert(
              id: alert.id,
              medicationName: alert.medicationName,
              reason: alert.reason,
              scheduledAt: alert.scheduledAt,
            ),
        ]),
        inventoryAvailable: inventoryAvailable,
      ),
    );
  }

  /// Days of history the family sees.
  static const historyDays = 7;

  @override
  Future<AppResult<List<IntakeHistoryEntry>>> history(String olderAdultId) =>
      caregiverMonitoringRequest(
        _store,
        (session) => _api.history(
          olderAdultId,
          session.owner.id,
          historyDays,
          session.accessToken,
        ),
        (response, _) => AppSuccess(MonitoringMapper.history(response.body)),
      );
}
