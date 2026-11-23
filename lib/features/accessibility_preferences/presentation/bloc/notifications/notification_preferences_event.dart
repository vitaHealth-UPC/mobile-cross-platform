import '../../../domain/value_objects/notification_preferences.dart';

/// Intents of the notification preferences screen.
sealed class NotificationPreferencesEvent {
  const NotificationPreferencesEvent();
}

final class NotificationPreferencesRequested
    extends NotificationPreferencesEvent {
  const NotificationPreferencesRequested();
}

final class ChannelToggled extends NotificationPreferencesEvent {
  const ChannelToggled(this.type, this.enabled);
  final ChannelType type;
  final bool enabled;
}

/// Turns quiet hours on with the suggested interval, or off when [enabled] is false.
final class QuietHoursToggled extends NotificationPreferencesEvent {
  const QuietHoursToggled(this.enabled);
  final bool enabled;
}

final class QuietHoursChanged extends NotificationPreferencesEvent {
  const QuietHoursChanged(this.quietHours);
  final QuietHours quietHours;
}

/// Raw contact typed in the form; validated by the bloc before saving.
final class ContactInput {
  const ContactInput(this.name, this.phone);
  final String name;
  final String phone;
}

/// Saves delivery policy and recipients in a single request. Blank
/// [dailySummary] means no daily summary.
final class PolicySaved extends NotificationPreferencesEvent {
  const PolicySaved({
    required this.reminder,
    required this.pending,
    required this.omitted,
    required this.escalation,
    required this.dailySummary,
    required this.contacts,
  });
  final String reminder;
  final String pending;
  final String omitted;
  final String escalation;
  final String dailySummary;
  final List<ContactInput> contacts;
}
