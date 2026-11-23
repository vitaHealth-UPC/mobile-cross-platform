import '../../application/readmodels/monitoring_readmodels.dart';
import '../../domain/entities/caregiver_alert.dart';
import '../../domain/entities/notes.dart';
import '../../domain/value_objects/adherence_counts.dart';
import '../../domain/value_objects/alert_status.dart';
import '../../domain/value_objects/contact_channel.dart';
import '../../domain/value_objects/note_values.dart';

/// Recent status of an older adult: weekly counts and the alerts that still need attention.
final class StatusReading {
  const StatusReading({required this.weekly, required this.openAlerts});
  final AdherenceCounts weekly;
  final List<CaregiverAlert> openAlerts;
}

/// A scheduled intake and the adult the server says it belongs to.
final class DoseReading {
  const DoseReading({required this.dose, required this.olderAdultId});
  final MonitoredDose dose;
  final String? olderAdultId;
}

/// Stock of one medication.
final class StockReading {
  const StockReading({
    required this.medicationId,
    required this.remaining,
    required this.low,
  });
  final String medicationId;
  final int remaining;
  final bool low;
}

/// Strict projections of the monitoring resources. Missing, mistyped or unknown values are
/// rejected instead of defaulted: a [FormatException] or [ArgumentError] becomes
/// `INVALID_RESPONSE` at the repository boundary.
abstract final class MonitoringMapper {
  static StatusReading status(Object? body) {
    final data = _object(body);
    final weekly = _object(data['weeklyAdherence']);
    final alerts = data['openAlerts'];
    final items = alerts == null ? const <Object?>[] : _list(alerts);
    return StatusReading(
      weekly: AdherenceCounts(
        _int(weekly, 'confirmedIntakes'),
        _int(weekly, 'totalIntakes'),
      ),
      openAlerts: _distinct(items.map(alert).toList(), (a) => a.id),
    );
  }

  static CaregiverAlert alert(Object? body) {
    final data = _object(body);
    final status = AlertStatus.fromWire(data['status']);
    if (status == null) throw const FormatException('Unknown alert status');
    final closed = data['closedAt'];
    return CaregiverAlert(
      id: _int(data, 'id'),
      intakeId: _text(data, 'intakeId'),
      medicationName: _text(data, 'medicationName'),
      scheduledAt: _instant(data, 'scheduledAt'),
      reason: _optionalText(data, 'reason') ?? '',
      status: status,
      openedAt: _instant(data, 'openedAt'),
      closedAt: closed == null ? null : _instant(data, 'closedAt'),
    );
  }

  static DoseReading dose(Object? body) {
    final data = _object(body);
    final status = _text(data, 'status');
    if (!MonitoredDose.statuses.contains(status)) {
      throw const FormatException('Unknown intake status');
    }
    return DoseReading(
      dose: MonitoredDose(
        id: _text(data, 'id'),
        medicationId: _text(data, 'medicationId'),
        medicationName: _text(data, 'medicationName'),
        dose: _text(data, 'dose'),
        scheduledAt: _instant(data, 'scheduledAt'),
        status: status,
      ),
      olderAdultId: _optionalText(data, 'olderAdultId'),
    );
  }

  static List<MonitoredDose> doses(Object? body) => _distinct(
    _list(body).map((item) => dose(item).dose).toList(),
    (dose) => dose.id,
  );

  static List<IntakeHistoryEntry> history(Object? body) =>
      _list(body).map((item) {
        final data = _object(item);
        final outcome = switch (_text(data, 'status')) {
          'CONFIRMED' => IntakeHistoryOutcome.confirmed,
          'LATE' => IntakeHistoryOutcome.late,
          'OMITTED' => IntakeHistoryOutcome.omitted,
          _ => throw const FormatException('Unknown history outcome'),
        };
        return IntakeHistoryEntry(
          medicationName: _text(data, 'medicationName'),
          scheduledAt: _instant(data, 'scheduledAt'),
          outcome: outcome,
        );
      }).toList();

  static StockReading inventory(Object? body) {
    final data = _object(body);
    final remaining = _int(data, 'remainingStock');
    final low = data['lowStock'];
    if (remaining < 0 || low is! bool) {
      throw const FormatException('Invalid stock');
    }
    return StockReading(
      medicationId: _text(data, 'medicationId'),
      remaining: remaining,
      low: low,
    );
  }

  static ContactChannel contact(Object? body) {
    final data = _object(body);
    final type = ContactChannelType.fromWire(data['type']);
    if (type == null) throw const FormatException('Unknown contact channel');
    return ContactChannel(type: type, value: _text(data, 'value'));
  }

  /// Identity and display name of the older adult; the birth date is optional.
  static MonitoredPerson person(Object? body) {
    final data = _object(body);
    final born = _optionalText(data, 'birthDate');
    DateTime? birthDate;
    if (born != null) {
      if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(born)) {
        throw const FormatException('Invalid birth date');
      }
      birthDate = DateTime.parse(born);
      if (birthDate.isAfter(DateTime.now())) {
        throw const FormatException('Birth date in the future');
      }
    }
    return MonitoredPerson(
      id: _text(data, 'id'),
      fullName: _text(data, 'fullName'),
      birthDate: birthDate,
    );
  }

  static List<RecordedAlertEvent> alertEvents(Object? body) {
    final events = _list(body).map((item) {
      final data = _object(item);
      final type = RecordedAlertEventType.fromWire(data['type']);
      if (type == null) throw const FormatException('Unknown alert event');
      return RecordedAlertEvent(
        type: type,
        occurredAt: _instant(data, 'occurredAt'),
      );
    }).toList();
    _distinct(events, (event) => event.type);
    return events;
  }

  static FollowUpNote followUpNote(Object? body) {
    final data = _object(body);
    return FollowUpNote(
      id: _int(data, 'id'),
      text: _string(data, 'text'),
      recordedAt: _instant(data, 'recordedAt'),
      familiarId: _text(data, 'familiarId'),
    );
  }

  static List<FollowUpNote> followUpNotes(Object? body) =>
      _distinct(_list(body).map(followUpNote).toList(), (note) => note.id);

  static PersonalNote personalNote(Object? body) {
    final data = _object(body);
    final category = PersonalNoteCategory.fromWire(data['category']);
    if (category == null) throw const FormatException('Unknown note category');
    return PersonalNote(
      id: _int(data, 'id'),
      title: _text(data, 'title'),
      text: _text(data, 'text'),
      category: category,
      recordedAt: _instant(data, 'recordedAt'),
    );
  }

  static List<PersonalNote> personalNotes(Object? body) =>
      _distinct(_list(body).map(personalNote).toList(), (note) => note.id);

  static Map<String, Object?> _object(Object? value) => value is Map
      ? Map<String, Object?>.from(value)
      : throw const FormatException('Expected an object');

  static List<Object?> _list(Object? value) =>
      value is List ? value : throw const FormatException('Expected a list');

  static String _string(Map<String, Object?> data, String key) {
    final value = data[key];
    return value is String ? value : throw FormatException('Missing $key');
  }

  static String _text(Map<String, Object?> data, String key) {
    final value = _string(data, key);
    if (value.trim().isEmpty) throw FormatException('Blank $key');
    return value;
  }

  static String? _optionalText(Map<String, Object?> data, String key) {
    final value = data[key];
    if (value == null) return null;
    if (value is! String) throw FormatException('Bad $key');
    return value.trim().isEmpty ? null : value;
  }

  static int _int(Map<String, Object?> data, String key) {
    final value = data[key];
    return value is int ? value : throw FormatException('Missing $key');
  }

  static final _instantShape = RegExp(
    r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}(:\d{2}(\.\d+)?)?(Z|[+-]\d{2}:\d{2})$',
  );

  /// Instants carry an explicit offset: a local date-time would depend on the device.
  static DateTime _instant(Map<String, Object?> data, String key) {
    final value = _string(data, key);
    final parsed = _instantShape.hasMatch(value)
        ? DateTime.tryParse(value)
        : null;
    if (parsed == null) throw FormatException('Invalid $key');
    return parsed.toUtc();
  }

  static List<T> _distinct<T, K>(List<T> items, K Function(T) key) {
    if (items.map(key).toSet().length != items.length) {
      throw const FormatException('Duplicate entries');
    }
    return List.unmodifiable(items);
  }
}
