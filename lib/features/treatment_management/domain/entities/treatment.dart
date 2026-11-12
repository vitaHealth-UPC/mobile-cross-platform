import '../value_objects/treatment_status.dart';

/// Treatment identity, adult ownership and current lifecycle state.
final class Treatment {
  Treatment({
    required this.id,
    required this.olderAdultId,
    required this.name,
    required this.status,
  }) {
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

  @override
  String toString() => 'Treatment[status=$status, clinicalData=REDACTED]';
}
