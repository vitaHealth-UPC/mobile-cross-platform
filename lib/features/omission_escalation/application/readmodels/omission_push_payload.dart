import 'dart:convert';

import '../../domain/value_objects/omission_push.dart';
import '../usecases/omission_usecases.dart';

/// Tap payload of a local notice: the references a tap needs, nothing clinical beyond the
/// medication name the notice already shows. It is untrusted input when it comes back, so
/// [decode] only builds a query that the policy still has to authorize.
abstract final class OmissionPushPayload {
  static String encode(OmissionPush push) => jsonEncode({
    'kind': push.kind.wireName,
    'olderAdultId': push.olderAdultId,
    'medicationName': push.medicationName,
    'intakeId': push.intakeId,
  });

  /// Null for any payload that did not come from an omission notice.
  static ResolvePushDestinationQuery? decode(String? payload) {
    if (payload == null) return null;
    final Object? json;
    try {
      json = jsonDecode(payload);
    } on FormatException {
      return null;
    }
    if (json is! Map<String, Object?>) return null;
    final kind = OmissionPushKind.fromWire(_text(json['kind']));
    final adult = _text(json['olderAdultId'])?.trim();
    if (kind == null || adult == null || adult.isEmpty) return null;
    final rawIntake = _text(json['intakeId']);
    if (rawIntake != null && rawIntake.trim().isEmpty) return null;
    final medication = _text(json['medicationName'])?.trim();
    return ResolvePushDestinationQuery(
      kind: kind,
      olderAdultId: adult,
      medicationName: medication == null || medication.isEmpty
          ? null
          : medication,
      intakeId: rawIntake?.trim(),
    );
  }

  static String? _text(Object? value) => value is String ? value : null;
}
