import '../../domain/entities/caregiver_alert.dart';
import '../../domain/value_objects/adherence_counts.dart';
import '../../domain/value_objects/contact_channel.dart';

/// Scheduled medication dose exposed to the family monitoring view.
final class MonitoredDose {
  const MonitoredDose({
    required this.id,
    required this.medicationId,
    required this.medicationName,
    required this.dose,
    required this.scheduledAt,
    required this.status,
  });

  /// `PENDING`, `CONFIRMED`, `LATE` or `OMITTED`, as the intake resource states it.
  static const statuses = {'PENDING', 'CONFIRMED', 'LATE', 'OMITTED'};

  final String id;
  final String medicationId;
  final String medicationName;
  final String dose;
  final DateTime scheduledAt;
  final String status;

  bool get isDone => status == 'CONFIRMED' || status == 'LATE';
}

/// Authorized profile evidence; an absent birth date never becomes a guessed age.
final class MonitoredPerson {
  const MonitoredPerson({
    required this.id,
    required this.fullName,
    required this.birthDate,
  });
  final String id;
  final String fullName;
  final DateTime? birthDate;

  /// Whole years at [now], or null when the profile has no birth date.
  int? ageAt(DateTime now) {
    final born = birthDate;
    if (born == null) return null;
    var years = now.year - born.year;
    if (now.month < born.month ||
        (now.month == born.month && now.day < born.day)) {
      years--;
    }
    return years < 0 ? null : years;
  }
}

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

/// Recorded outcomes supported by the family intake history.
enum IntakeHistoryOutcome { confirmed, late, omitted }

/// A historical intake without display formatting or a device-specific time zone.
final class IntakeHistoryEntry {
  const IntakeHistoryEntry({
    required this.medicationName,
    required this.scheduledAt,
    required this.outcome,
  });
  final String medicationName;
  final DateTime scheduledAt;
  final IntakeHistoryOutcome outcome;
}

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

/// What the alert detail and the family summary need to offer contact: [channel] is null
/// when none exists.
final class ContactOption {
  const ContactOption({required this.channel, required this.firstName});
  final ContactChannel? channel;
  final String? firstName;
}

/// One step the backend recorded for an alert.
final class RecordedAlertEvent {
  const RecordedAlertEvent({required this.type, required this.occurredAt});
  final RecordedAlertEventType type;
  final DateTime occurredAt;
}

enum RecordedAlertEventType {
  intakeScheduled('INTAKE_SCHEDULED'),
  reinforcedReminderSent('REINFORCED_REMINDER_SENT'),
  alertGenerated('ALERT_GENERATED'),
  alertClosed('ALERT_CLOSED');

  const RecordedAlertEventType(this.wireName);
  final String wireName;

  static RecordedAlertEventType? fromWire(Object? value) {
    for (final type in values) {
      if (type.wireName == value) return type;
    }
    return null;
  }
}
