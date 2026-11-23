import '../readmodels/intake_reminder.dart';

/// Device notifications for doses, delivered even while the app is closed.
abstract interface class ReminderScheduler {
  /// Asks for permission once and prepares the channel; never throws.
  Future<void> prepare();

  /// Replaces every scheduled reminder of this app with [reminders].
  Future<void> replaceAll(List<IntakeReminder> reminders);

  /// Removes scheduled and displayed reminders.
  Future<void> cancelAll();

  /// Dose identifiers of reminders the adult tapped while the app was running.
  Stream<String> get opened;

  /// Dose identifier of the reminder that launched the app, if any; read once.
  Future<String?> takeLaunchDose();
}
