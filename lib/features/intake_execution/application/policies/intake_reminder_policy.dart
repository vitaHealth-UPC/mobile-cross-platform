import '../../domain/entities/intake.dart';
import '../readmodels/intake_reminder.dart';

/// Decides the device reminders of the coming doses (US-05 and US-22).
abstract final class IntakeReminderPolicy {
  /// Mirrors the backend default (tata.intake.unconfirmed-after = PT15M), when
  /// the server reports the dose as unconfirmed and sends its reinforced reminder.
  static const reinforceAfter = Duration(minutes: 15);

  /// How far ahead reminders are scheduled from the stored agenda.
  static const horizon = Duration(hours: 48);

  /// Keeps the alarms of one app well below platform limits.
  static const limit = 48;

  /// Only a dose still pending on the server and on this device is reminded,
  /// so a confirmed or queued dose produces nothing (US-05 and US-22, AC2).
  static List<IntakeReminder> plan(Iterable<Intake> intakes, DateTime now) {
    final instant = now.toUtc();
    final end = instant.add(horizon);
    final reminders = <IntakeReminder>[];
    for (final intake in intakes) {
      if (!intake.confirmable) continue;
      for (final (kind, at) in [
        (ReminderKind.due, intake.scheduledAt),
        (ReminderKind.reinforced, intake.scheduledAt.add(reinforceAfter)),
      ]) {
        if (!at.isAfter(instant) || at.isAfter(end)) continue;
        reminders.add(
          IntakeReminder(
            intakeId: intake.id,
            kind: kind,
            at: at,
            medicationName: intake.medicationName,
            dose: intake.dose,
          ),
        );
      }
    }
    reminders.sort((a, b) => a.at.compareTo(b.at));
    return reminders.take(limit).toList();
  }
}
