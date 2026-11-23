import '../../domain/entities/user_preferences.dart';
import '../../domain/value_objects/accessibility_preferences.dart';
import '../../domain/value_objects/notification_preferences.dart';

/// Strict projection of the preferences snapshot: absent, mistyped or unknown values are
/// rejected instead of defaulted, so `false` is never confused with "missing".
abstract final class UserPreferencesMapper {
  static UserPreferences preferences(Object? body, String requestedUserId) {
    final data = _object(body);
    if (requestedUserId.trim().isEmpty || data['userId'] != requestedUserId) {
      throw const FormatException('Preferences of another user');
    }
    final textSize = TextSizeLevel.fromWire(data['textSize']);
    if (textSize == null) throw const FormatException('Unknown text size');
    final dark = data['darkTheme'];
    if (dark != null && dark is! bool) throw const FormatException();

    final channels = _list(data['notificationChannels']).map((item) {
      final channel = _object(item);
      final type = ChannelType.fromWire(channel['type']);
      final enabled = channel['enabled'];
      if (type == null || enabled is! bool) throw const FormatException();
      return NotificationChannel(type, enabled);
    }).toList();
    if (channels.map((c) => c.type).toSet().length != channels.length) {
      throw const FormatException('Duplicate channels');
    }

    QuietHours? quietHours;
    final quiet = data['quietHours'];
    if (quiet != null) {
      final range = _object(quiet);
      final start = parseTime(range['start']);
      final end = parseTime(range['end']);
      if (start == null || end == null) throw const FormatException();
      quietHours =
          QuietHours.tryCreate(start.$1, start.$2, end.$1, end.$2) ??
          (throw const FormatException('Invalid quiet hours'));
    }

    final policy = _object(data['notificationPolicy']);
    final summary = policy['dailySummaryTime'];
    final summaryTime = summary == null ? null : parseTime(summary);
    if (summary != null && summaryTime == null) throw const FormatException();
    final parsedPolicy =
        NotificationPolicy.tryCreate(
          reminderMinutes: _int(policy, 'reminderMinutes'),
          pendingAlertMinutes: _int(policy, 'pendingAlertMinutes'),
          omittedAlertMinutes: _int(policy, 'omittedAlertMinutes'),
          escalationMinutes: _int(policy, 'escalationMinutes'),
          dailySummaryHour: summaryTime?.$1,
          dailySummaryMinute: summaryTime?.$2,
        ) ??
        (throw const FormatException('Invalid policy'));

    final contacts = _list(data['emergencyContacts']).map((item) {
      final contact = _object(item);
      final name = contact['name'];
      final phone = contact['phone'];
      if (name is! String || phone is! String) throw const FormatException();
      return EmergencyContact.tryCreate(name, phone) ??
          (throw const FormatException('Invalid contact'));
    }).toList();
    if (contacts.length > 5 ||
        contacts.map((c) => c.phone.replaceFirst('+', '')).toSet().length !=
            contacts.length) {
      throw const FormatException('Invalid contacts');
    }

    return UserPreferences(
      userId: requestedUserId,
      accessibility: AccessibilityPreferences(
        textSize: textSize,
        highContrast: _bool(data, 'highContrast'),
        reducedMotion: _bool(data, 'reducedMotion'),
        readingAssistance: _bool(data, 'readingAssistance'),
        voiceConfirmation: _bool(data, 'voiceConfirmationEnabled'),
        darkTheme: dark as bool? ?? false,
      ),
      notifications: NotificationPreferences(
        quietHours: quietHours,
        channels: List.unmodifiable(channels),
        policy: parsedPolicy,
        emergencyContacts: List.unmodifiable(contacts),
      ),
    );
  }

  /// Accepts backend minute-precision times without discarding nonzero seconds.
  static (int, int)? parseTime(Object? value) => parseHourMinute(value);

  /// Formats a time of day as the `HH:mm` the backend reads.
  static String formatTime(int hour, int minute) =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  static Map<String, dynamic> _object(Object? value) {
    if (value is! Map<String, dynamic>) throw const FormatException();
    return value;
  }

  static List<Object?> _list(Object? value) {
    if (value is! List) throw const FormatException();
    return value;
  }

  static bool _bool(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value is! bool) throw FormatException('Missing $key');
    return value;
  }

  static int _int(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value is! int) throw FormatException('Missing $key');
    return value;
  }
}
