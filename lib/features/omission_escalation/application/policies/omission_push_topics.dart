import '../../domain/value_objects/omission_push.dart';

/// Recipients of the backend `PushProviderMessage`: `user-<olderAdultId>` for the reminder and
/// `caregivers-of-<olderAdultId>` for the caregiver alert. A device that follows them as
/// topics receives the sender as `/topics/<name>`.
abstract final class OmissionPushTopics {
  static const _topicPrefix = '/topics/';
  static const _olderAdultPrefix = 'user-';
  static const _caregiversPrefix = 'caregivers-of-';

  static String forOlderAdult(String olderAdultId) =>
      _olderAdultPrefix + olderAdultId.trim();

  static String forCaregiversOf(String olderAdultId) =>
      _caregiversPrefix + olderAdultId.trim();

  // Legacy English messages: the backend owns the text and the clinical omission state, the
  // device only extracts the medication to build its own localized notice.
  static final _reminderBody = RegExp(
    r'^Your (.+) is still pending\. Please confirm it when you take it\.$',
  );
  static final _caregiverBody = RegExp(
    r'^(.+) was not confirmed\. Please check how they are doing\.$',
  );

  /// Returns null for messages that do not come from an omission topic.
  static OmissionPush? parse(String? from, String? body) {
    if (from == null || !from.startsWith(_topicPrefix)) return null;
    final topic = from.substring(_topicPrefix.length);
    if (topic.startsWith(_caregiversPrefix)) {
      final id = _id(topic.substring(_caregiversPrefix.length));
      return id == null
          ? null
          : OmissionPush(
              kind: OmissionPushKind.caregiverAlert,
              olderAdultId: id,
              medicationName: _medication(_caregiverBody, body),
            );
    }
    if (topic.startsWith(_olderAdultPrefix)) {
      final id = _id(topic.substring(_olderAdultPrefix.length));
      return id == null
          ? null
          : OmissionPush(
              kind: OmissionPushKind.reinforcedReminder,
              olderAdultId: id,
              medicationName: _medication(_reminderBody, body),
            );
    }
    return null;
  }

  static String? _id(String value) =>
      value.trim().isEmpty || RegExp(r'[\s/]').hasMatch(value) ? null : value;

  static String? _medication(RegExp pattern, String? body) =>
      body == null ? null : pattern.firstMatch(body.trim())?.group(1);
}
