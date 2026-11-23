import '../../application/readmodels/treatment_readmodels.dart';
import '../../domain/entities/medication.dart';
import '../../domain/entities/treatment.dart';
import '../../domain/value_objects/administration_schedule.dart';
import '../../domain/value_objects/treatment_status.dart';

/// Strict projections of medication and treatment resources.
/// Missing, mistyped or unknown values are rejected instead of defaulted.
abstract final class TreatmentMapper {
  static Medication medication(Object? body) {
    final data = _object(body);
    final active = data['active'];
    if (active is! bool) throw const FormatException('Missing availability');
    return Medication(
      id: _text(data, 'id'),
      olderAdultId: _text(data, 'olderAdultId'),
      name: _text(data, 'name'),
      presentation: _text(data, 'presentation'),
      active: active,
    );
  }

  static List<Medication> medications(Object? body) {
    final items = _list(body).map(medication).toList();
    if (items.map((item) => item.id).toSet().length != items.length) {
      throw const FormatException('Duplicate medications');
    }
    return List.unmodifiable(items);
  }

  /// Draft-or-later treatment identity without its regimen.
  static Treatment treatment(Object? body) {
    final data = _object(body);
    return Treatment(
      id: _text(data, 'id'),
      olderAdultId: _text(data, 'olderAdultId'),
      name: _text(data, 'name'),
      status: _status(data),
    );
  }

  static TreatmentDetail detail(Object? body) {
    final data = _object(body);
    final instructions = data['instructions'];
    if (instructions != null && instructions is! String) {
      throw const FormatException('Bad instructions');
    }
    final times = data['scheduledTimes'];
    final scheduled = times == null
        ? <String>[]
        : (times is List ? times : throw const FormatException('Bad times'))
              .map(_time)
              .toList();
    if (scheduled.toSet().length != scheduled.length) {
      throw const FormatException('Duplicate times');
    }
    scheduled.sort();
    return TreatmentDetail(
      id: _text(data, 'id'),
      olderAdultId: _text(data, 'olderAdultId'),
      name: _text(data, 'name'),
      status: _status(data),
      medicationId: _optionalText(data, 'medicationId'),
      dose: _optionalText(data, 'dose'),
      frequency: _optionalText(data, 'frequency'),
      scheduledTimes: List.unmodifiable(scheduled),
      instructions: instructions as String? ?? '',
      reminderLeadMinutes: _minutes(data, 'reminderLeadMinutes'),
      followUpDelayMinutes: _minutes(data, 'followUpDelayMinutes'),
      recurrenceZone: _optionalText(data, 'recurrenceZone'),
    );
  }

  static List<TreatmentDetail> details(Object? body) {
    final items = _list(body).map(detail).toList();
    if (items.map((item) => item.id).toSet().length != items.length) {
      throw const FormatException('Duplicate treatments');
    }
    return List.unmodifiable(items);
  }

  /// Catalog entries of the older adult, each with its related treatments.
  static List<MyMedication> myMedications(Object? body, {String? ownerId}) {
    final seen = <String>{};
    return List.unmodifiable(
      _list(body).map((item) {
        final data = _object(item);
        final medication = TreatmentMapper.medication(data['medication']);
        if ((ownerId != null && medication.olderAdultId != ownerId) ||
            !seen.add(medication.id)) {
          throw const FormatException('Duplicate medications');
        }
        final related = details(data['treatments']);
        for (final treatment in related) {
          if (!treatment.configured ||
              treatment.medicationId == null ||
              treatment.olderAdultId != medication.olderAdultId ||
              (treatment.medicationId != null &&
                  treatment.medicationId != medication.id)) {
            throw const FormatException('Foreign treatment');
          }
        }
        final regimen =
            related
                .where(
                  (treatment) => treatment.status == TreatmentStatus.active,
                )
                .firstOrNull ??
            related.firstOrNull;
        return MyMedication(
          id: medication.id,
          name: medication.name,
          presentation: medication.presentation,
          active:
              medication.active &&
              related.any(
                (treatment) => treatment.status == TreatmentStatus.active,
              ),
          dose: regimen?.dose ?? '',
          instructions: regimen?.instructions ?? '',
          scheduledTimes: regimen?.scheduledTimes ?? const [],
          treatments: List.unmodifiable(related),
        );
      }),
    );
  }

  static TreatmentStatus _status(Map<String, dynamic> data) =>
      TreatmentStatus.fromWire(data['status']) ??
      (throw const FormatException('Unknown treatment status'));

  static String _time(Object? value) {
    final parsed = value is String ? ClockTime.tryParseServer(value) : null;
    if (parsed == null) throw const FormatException('Bad time');
    return parsed.toString();
  }

  static int? _minutes(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value == null) return null;
    if (value is! int || value < 0 || value > 1440) {
      throw const FormatException('Bad minutes');
    }
    return value;
  }

  static List<Object?> _list(Object? body) {
    if (body is! List) throw const FormatException('Expected a list');
    return body;
  }

  static Map<String, dynamic> _object(Object? body) {
    if (body is! Map<String, dynamic>) throw const FormatException();
    return body;
  }

  static String _text(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value is! String || value.trim().isEmpty) {
      throw FormatException('Bad $key');
    }
    return value;
  }

  static String? _optionalText(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value == null) return null;
    if (value is! String) throw FormatException('Bad $key');
    return value.isEmpty ? null : value;
  }
}
