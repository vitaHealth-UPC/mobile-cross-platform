import '../../domain/value_objects/treatment_status.dart';

/// Treatment identity, lifecycle state and optional regimen details for read-only views.
/// A draft carries no regimen; the client never invents one.
final class TreatmentDetail {
  const TreatmentDetail({
    required this.id,
    required this.olderAdultId,
    required this.name,
    required this.status,
    this.medicationId,
    this.dose,
    this.frequency,
    this.scheduledTimes = const [],
    this.instructions = '',
    this.reminderLeadMinutes,
    this.followUpDelayMinutes,
    this.recurrenceZone,
    this.recurrenceMode,
    this.recurrenceAnchor,
    String? planId,
  }) : planId = planId ?? id;

  final String id;
  final String olderAdultId;
  final String name;
  final TreatmentStatus status;
  final String? medicationId;
  final String? dose;
  final String? frequency;

  /// Local times as `HH:mm`, in ascending order.
  final List<String> scheduledTimes;
  final String instructions;
  final int? reminderLeadMinutes;

  /// Null when the system default follow-up applies.
  final int? followUpDelayMinutes;
  final String? recurrenceZone;
  final String? recurrenceMode;
  final DateTime? recurrenceAnchor;

  /// Plan shared with the other medications of the same treatment.
  final String planId;

  bool get isDraft => status == TreatmentStatus.draft;

  /// True when a regimen was configured for this treatment.
  bool get configured =>
      dose != null && frequency != null && scheduledTimes.isNotEmpty;

  @override
  String toString() => 'TreatmentDetail[status=$status, clinicalData=REDACTED]';
}
