import '../../domain/entities/caregiver_alert.dart';
import 'monitored_dose.dart';

/// Alert follow-up and dose events retain their distinct identities and actions.
final class AlertTimeline {
  const AlertTimeline({
    required this.alerts,
    required this.doses,
    required this.olderAdultName,
    required this.day,
  });
  final List<CaregiverAlert> alerts;
  final List<MonitoredDose> doses;
  final String olderAdultName;
  final DateTime day;
}
