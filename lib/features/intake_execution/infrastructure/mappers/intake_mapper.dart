import '../../domain/entities/intake.dart';

/// Converts untrusted intake JSON into domain intakes.
/// Throws [FormatException] for missing fields, unknown statuses or local timestamps.
abstract final class IntakeMapper {
  static Intake intake(Object? body) {
    if (body is! Map<String, dynamic>) throw const FormatException();
    final instructions = body['instructions'];
    if (instructions != null && instructions is! String) {
      throw const FormatException();
    }
    return Intake(
      id: _text(body, 'id'),
      olderAdultId: _text(body, 'olderAdultId'),
      medicationName: _text(body, 'medicationName'),
      dose: _text(body, 'dose'),
      instructions: instructions is String ? instructions : null,
      scheduledAt: _instant(body, 'scheduledAt'),
      status: switch (body['status']) {
        'PENDING' => IntakeStatus.pending,
        'CONFIRMED' => IntakeStatus.confirmed,
        'LATE' => IntakeStatus.late,
        'OMITTED' => IntakeStatus.omitted,
        _ => throw const FormatException(),
      },
    );
  }

  static List<Intake> agenda(Object? body) {
    if (body is! List<dynamic>) throw const FormatException();
    return [for (final item in body) intake(item)];
  }

  static String _text(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value is! String || value.trim().isEmpty) {
      throw const FormatException();
    }
    return value;
  }

  // An offset is required: a local timestamp would shift the dose time.
  static DateTime _instant(Map<String, dynamic> data, String key) {
    final value = _text(data, key);
    if (!RegExp(r'(Z|[+-]\d{2}:\d{2})$').hasMatch(value)) {
      throw const FormatException();
    }
    return DateTime.parse(value).toUtc();
  }
}
