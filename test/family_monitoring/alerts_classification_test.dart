import 'package:flutter_test/flutter_test.dart';
import 'package:tata/features/family_monitoring/domain/value_objects/alert_severity.dart';
import 'package:tata/features/family_monitoring/domain/value_objects/alert_status.dart';
import 'package:tata/features/family_monitoring/infrastructure/mappers/monitoring_mapper.dart';
import 'package:tata/features/family_monitoring/presentation/bloc/alerts/alerts_bloc.dart';

void main() {
  Map<String, Object?> alert({String? severity, String status = 'OPEN'}) => {
    'id': 1,
    'intakeId': 'intake-A',
    'medicationName': 'Losartán',
    'scheduledAt': '2026-11-18T08:00:00Z',
    'openedAt': '2026-11-18T08:30:00Z',
    'reason': 'No confirmation',
    'status': status,
    'closedAt': status == 'CLOSED' ? '2026-11-18T09:00:00Z' : null,
    'severity': ?severity,
  };

  for (final severity in AlertSeverity.values) {
    test(
      'reads server priority ${severity.wireName} without a device-clock rule',
      () {
        final value = MonitoringMapper.alert(
          alert(severity: severity.wireName),
        );
        expect(value.severity, severity);
      },
    );
  }

  test('a legacy response remains unknown despite its age', () {
    final data = alert()..['scheduledAt'] = '2020-01-01T08:00:00Z';
    final value = MonitoringMapper.alert(data);
    expect(value.severity, AlertSeverity.unknown);
    expect(AlertsState(alerts: [value]).severityKnown, isFalse);
  });

  test(
    'unrecognized or mistyped priorities cannot create an all-clear result',
    () {
      expect(
        () => MonitoringMapper.alert(alert(severity: 'URGENT')),
        throwsFormatException,
      );
      expect(
        () => MonitoringMapper.alert(alert()..['severity'] = true),
        throwsFormatException,
      );
    },
  );

  test(
    'critical follow-ups include attended alerts until explicit closure',
    () {
      final open = MonitoringMapper.alert(alert(severity: 'CRITICAL'));
      final attended = MonitoringMapper.alert(
        alert(severity: 'CRITICAL', status: 'ATTENDED'),
      );
      final closed = MonitoringMapper.alert(
        alert(severity: 'CRITICAL', status: 'CLOSED'),
      );
      final state = AlertsState(alerts: [open, attended, closed]);
      expect(state.criticalCount, 2);
      expect(state.severityKnown, isTrue);
      expect(state.copyWith(filter: AlertFilter.completed).criticalCount, 2);
      expect(attended.status, AlertStatus.attended);
    },
  );

  test(
    'unknown open evidence blocks all-clear while closed evidence does not',
    () {
      final unknown = MonitoringMapper.alert(alert());
      final closedUnknown = MonitoringMapper.alert(alert(status: 'CLOSED'));
      final critical = MonitoringMapper.alert(alert(severity: 'CRITICAL'));
      expect(AlertsState(alerts: [unknown, critical]).criticalCount, 1);
      expect(AlertsState(alerts: [unknown, critical]).severityKnown, isFalse);
      expect(AlertsState(alerts: [closedUnknown]).severityKnown, isTrue);
      expect(const AlertsState().severityKnown, isTrue);
    },
  );

  test('confirmation evidence is separate from the scheduled instant', () {
    final json = <String, Object?>{
      'id': 'dose',
      'medicationId': 'med',
      'medicationName': 'Losartán',
      'dose': '1 tableta',
      'scheduledAt': '2026-11-18T08:00:00Z',
      'status': 'CONFIRMED',
      'confirmedAt': '2026-11-18T07:58:00Z',
    };
    final dose = MonitoringMapper.dose(json).dose;
    expect(dose.scheduledAt, DateTime.utc(2026, 11, 18, 8));
    expect(dose.confirmedAt, DateTime.utc(2026, 11, 18, 7, 58));
    expect(
      MonitoringMapper.dose({...json}..remove('confirmedAt')).dose.confirmedAt,
      isNull,
    );
    expect(
      () => MonitoringMapper.dose({...json, 'status': 'PENDING'}),
      throwsFormatException,
    );
  });
}
