import '../../domain/value_objects/adherence_counts.dart';
import 'monitored_dose.dart';

/// Open follow-up alert associated with a scheduled intake.
final class OpenAlert {
  const OpenAlert({
    required this.id,
    required this.medicationName,
    required this.reason,
    required this.scheduledAt,
  });
  final int id;
  final String medicationName;
  final String reason;
  final DateTime scheduledAt;
}

/// Remaining medication stock requiring caregiver attention.
final class StockAttention {
  const StockAttention({
    required this.medicationId,
    required this.medicationName,
    required this.remaining,
  });
  final String medicationId;
  final String medicationName;
  final int remaining;
}

/// Daily family monitoring snapshot combining adherence, agenda, stock and alerts.
final class FamilySummary {
  const FamilySummary({
    required this.olderAdultName,
    required this.date,
    required this.weekly,
    required this.today,
    required this.nextDose,
    required this.stockAttention,
    required this.openAlerts,
    required this.inventoryAvailable,
  });
  final String olderAdultName;
  final DateTime date;
  final AdherenceCounts weekly;
  final AdherenceCounts today;
  final MonitoredDose? nextDose;
  final List<StockAttention> stockAttention;
  final List<OpenAlert> openAlerts;

  /// False when stock could not be read, so "no low stock" is not shown as good news.
  final bool inventoryAvailable;
}
