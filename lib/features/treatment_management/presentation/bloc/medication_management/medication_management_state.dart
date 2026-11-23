import '../../../domain/entities/medication.dart';

enum MedicationManagementStatus { loading, ready, failure }

/// Outcome of the last successful change, shown once as a notice.
enum MedicationNotice { updated, deactivated, reactivated }

/// Medications of one adult with the pending operation and the last outcome.
final class MedicationManagementState {
  const MedicationManagementState({
    this.status = MedicationManagementStatus.loading,
    this.medications = const [],
    this.busy = false,
    this.notice,
    this.errorCode,
  });

  final MedicationManagementStatus status;
  final List<Medication> medications;

  /// True while an edit, deactivation or reactivation is in flight.
  final bool busy;
  final MedicationNotice? notice;
  final String? errorCode;

  MedicationManagementState copyWith({
    MedicationManagementStatus? status,
    List<Medication>? medications,
    bool? busy,
    MedicationNotice? notice,
    String? errorCode,
  }) => MedicationManagementState(
    status: status ?? this.status,
    medications: medications ?? this.medications,
    busy: busy ?? this.busy,
    notice: notice,
    errorCode: errorCode,
  );
}
