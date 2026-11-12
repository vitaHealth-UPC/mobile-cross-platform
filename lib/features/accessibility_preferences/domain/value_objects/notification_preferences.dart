/// Parses `HH:mm` (optionally with zero seconds) into (hour, minute); null when invalid.
(int, int)? parseHourMinute(Object? value) {
  if (value is! String) return null;
  final match = RegExp(
    r'^([01][0-9]|2[0-3]):([0-5][0-9])(?::00(?:\.0{1,9})?)?$',
  ).firstMatch(value);
  return match == null
      ? null
      : (int.parse(match.group(1)!), int.parse(match.group(2)!));
}

/// Delivery channel identifiers supported by notification preferences.
enum ChannelType {
  push('PUSH'),
  sms('SMS'),
  email('EMAIL'),
  call('CALL');

  const ChannelType(this.wire);
  final String wire;

  static ChannelType? fromWire(Object? value) {
    for (final type in values) {
      if (type.wire == value) return type;
    }
    return null;
  }
}

/// Delivery channel selection and whether that channel is enabled.
final class NotificationChannel {
  const NotificationChannel(this.type, this.enabled);
  final ChannelType type;
  final bool enabled;

  NotificationChannel copyWith({bool? enabled}) =>
      NotificationChannel(type, enabled ?? this.enabled);
}

/// Daily interval in which non-critical notifications are held back. It may cross
/// midnight, for example 22:00 to 07:00.
final class QuietHours {
  QuietHours(this.startHour, this.startMinute, this.endHour, this.endMinute) {
    if (startHour < 0 ||
        startHour > 23 ||
        endHour < 0 ||
        endHour > 23 ||
        startMinute < 0 ||
        startMinute > 59 ||
        endMinute < 0 ||
        endMinute > 59 ||
        (startHour == endHour && startMinute == endMinute)) {
      throw ArgumentError('Invalid quiet hours');
    }
  }

  /// Suggested interval the first time the user turns quiet hours on.
  factory QuietHours.suggested() => QuietHours(22, 0, 7, 0);

  /// Null when the interval is not valid, for example when it starts and ends together.
  static QuietHours? tryCreate(int sh, int sm, int eh, int em) {
    try {
      return QuietHours(sh, sm, eh, em);
    } on ArgumentError {
      return null;
    }
  }

  final int startHour;
  final int startMinute;
  final int endHour;
  final int endMinute;

  @override
  bool operator ==(Object other) =>
      other is QuietHours &&
      startHour == other.startHour &&
      startMinute == other.startMinute &&
      endHour == other.endHour &&
      endMinute == other.endMinute;

  @override
  int get hashCode => Object.hash(startHour, startMinute, endHour, endMinute);
}

/// Recipient configured by the user; this does not establish a care relationship.
final class EmergencyContact {
  EmergencyContact._(this.name, this.phone);

  final String name;
  final String phone;

  static final _phone = RegExp(r'^\+?[0-9]{7,15}$');

  /// Normalizes spaces, parentheses and dashes; null when the data is not acceptable.
  static EmergencyContact? tryCreate(String name, String phone) {
    final cleanName = name.trim();
    final cleanPhone = phone.trim().replaceAll(RegExp(r'[\s()\-]'), '');
    if (cleanName.isEmpty ||
        cleanName.length > 80 ||
        !_phone.hasMatch(cleanPhone)) {
      return null;
    }
    return EmergencyContact._(cleanName, cleanPhone);
  }

  @override
  bool operator ==(Object other) =>
      other is EmergencyContact && name == other.name && phone == other.phone;

  @override
  int get hashCode => Object.hash(name, phone);

  @override
  String toString() => 'EmergencyContact[personalData=REDACTED]';
}

/// Delays from the scheduled intake. They control notices, never treatment dosage.
final class NotificationPolicy {
  NotificationPolicy._(
    this.reminderMinutes,
    this.pendingAlertMinutes,
    this.omittedAlertMinutes,
    this.escalationMinutes,
    this.dailySummaryHour,
    this.dailySummaryMinute,
  );

  final int reminderMinutes;
  final int pendingAlertMinutes;
  final int omittedAlertMinutes;
  final int escalationMinutes;
  final int? dailySummaryHour;
  final int? dailySummaryMinute;

  /// Delays must grow strictly from reminder to escalation, up to one day. The daily
  /// summary needs both hour and minute or neither. Null when the policy is invalid.
  static NotificationPolicy? tryCreate({
    required int reminderMinutes,
    required int pendingAlertMinutes,
    required int omittedAlertMinutes,
    required int escalationMinutes,
    int? dailySummaryHour,
    int? dailySummaryMinute,
  }) {
    final summaryValid =
        (dailySummaryHour == null) == (dailySummaryMinute == null) &&
        (dailySummaryHour == null ||
            (dailySummaryHour >= 0 && dailySummaryHour <= 23)) &&
        (dailySummaryMinute == null ||
            (dailySummaryMinute >= 0 && dailySummaryMinute <= 59));
    if (reminderMinutes < 1 ||
        escalationMinutes > 1440 ||
        !(reminderMinutes < pendingAlertMinutes &&
            pendingAlertMinutes < omittedAlertMinutes &&
            omittedAlertMinutes < escalationMinutes) ||
        !summaryValid) {
      return null;
    }
    return NotificationPolicy._(
      reminderMinutes,
      pendingAlertMinutes,
      omittedAlertMinutes,
      escalationMinutes,
      dailySummaryHour,
      dailySummaryMinute,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is NotificationPolicy &&
      reminderMinutes == other.reminderMinutes &&
      pendingAlertMinutes == other.pendingAlertMinutes &&
      omittedAlertMinutes == other.omittedAlertMinutes &&
      escalationMinutes == other.escalationMinutes &&
      dailySummaryHour == other.dailySummaryHour &&
      dailySummaryMinute == other.dailySummaryMinute;

  @override
  int get hashCode => Object.hash(
    reminderMinutes,
    pendingAlertMinutes,
    omittedAlertMinutes,
    escalationMinutes,
    dailySummaryHour,
    dailySummaryMinute,
  );
}

/// Delivery configuration combining quiet hours, recipients, policy and channels.
final class NotificationPreferences {
  const NotificationPreferences({
    this.quietHours,
    this.policy,
    this.emergencyContacts = const [],
    this.channels = const [
      NotificationChannel(ChannelType.push, true),
      NotificationChannel(ChannelType.sms, false),
      NotificationChannel(ChannelType.email, false),
      NotificationChannel(ChannelType.call, false),
    ],
  });

  /// Null when quiet hours are off.
  final QuietHours? quietHours;

  /// Null when connected to a service without the notification policy contract.
  final NotificationPolicy? policy;
  final List<EmergencyContact> emergencyContacts;
  final List<NotificationChannel> channels;

  bool isEnabled(ChannelType type) =>
      channels.where((channel) => channel.type == type).firstOrNull?.enabled ??
      false;

  NotificationPreferences copyWith({
    QuietHours? quietHours,
    bool clearQuietHours = false,
    List<NotificationChannel>? channels,
  }) => NotificationPreferences(
    quietHours: clearQuietHours ? null : quietHours ?? this.quietHours,
    policy: policy,
    emergencyContacts: emergencyContacts,
    channels: channels ?? this.channels,
  );
}
