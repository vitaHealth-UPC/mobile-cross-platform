import '../../application/policies/omission_push_topics.dart';
import '../../domain/value_objects/omission_push.dart';

/// Maps the backend's versioned push data contract without parsing localized text.
/// Anything that does not carry the complete version-1 contract is ignored.
OmissionPush? omissionPushFromData(Map<String, String> data) {
  if (data['schemaVersion'] != '1') return null;
  final kind = OmissionPushKind.fromWire(data['kind']);
  final adult = _present(data['olderAdultId']);
  final delivery = _present(data['deliveryId']);
  final intake = _present(data['intakeId']);
  final medication = _present(data['medicationName']);
  final scheduled = DateTime.tryParse(data['scheduledAt'] ?? '');
  if (kind == null ||
      adult == null ||
      delivery == null ||
      intake == null ||
      medication == null ||
      scheduled == null) {
    return null;
  }
  return OmissionPush(
    kind: kind,
    olderAdultId: adult,
    medicationName: medication,
    deliveryId: delivery,
    intakeId: intake,
    scheduledAt: scheduled.toUtc(),
  );
}

/// A message is either a versioned data message or a legacy topic message.
OmissionPush? omissionPushFromMessage({
  required Map<String, String> data,
  String? from,
  String? body,
}) => data.containsKey('schemaVersion')
    ? omissionPushFromData(data)
    : OmissionPushTopics.parse(from, body ?? data['body']);

String? _present(String? value) =>
    value == null || value.trim().isEmpty ? null : value;
