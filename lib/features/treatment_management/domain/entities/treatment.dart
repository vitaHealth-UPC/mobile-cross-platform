import '../value_objects/treatment_status.dart';

/// Treatment identity, adult ownership and current lifecycle state.
final class Treatment {
  Treatment({
    required this.id,
    required this.olderAdultId,
    required this.name,
    required this.status,
    String? planId,
  }) : planId = planId == null || planId.trim().isEmpty ? id : planId {
    if (id.trim().isEmpty ||
        olderAdultId.trim().isEmpty ||
        name.trim().isEmpty) {
      throw ArgumentError('Invalid treatment');
    }
  }

  final String id;
  final String olderAdultId;
  final String name;
  final TreatmentStatus status;

  /// Treatment plan shared by the regimens of one treatment with several
  /// medications; a standalone regimen is its own plan.
  final String planId;

  @override
  String toString() => 'Treatment[status=$status, clinicalData=REDACTED]';
}
