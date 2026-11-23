import '../../domain/entities/caregiver_alert.dart';

/// Pending alerts first, then attended and closed ones; the most recent intake first inside
/// each group.
int compareAlerts(CaregiverAlert a, CaregiverAlert b) {
  final byStatus = a.status.index.compareTo(b.status.index);
  return byStatus != 0 ? byStatus : b.scheduledAt.compareTo(a.scheduledAt);
}
