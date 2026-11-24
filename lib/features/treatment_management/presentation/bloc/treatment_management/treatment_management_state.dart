import '../../../application/readmodels/treatment_detail.dart';
import '../../../domain/entities/medication.dart';

enum TreatmentManagementStatus { loading, ready, failure }

/// Successful operation acknowledged by the server, cleared by the next attempt.
enum TreatmentManagementNotice {
  regimenSaved,
  medicationDeactivated,
  medicationReactivated,
}

/// Treatment, its medication and the state of the current operation.
final class TreatmentManagementState {
  const TreatmentManagementState({
    this.status = TreatmentManagementStatus.loading,
    this.detail,
    this.medication,
    this.activeMedicationCount,
    this.busy = false,
    this.notice,
    this.errorCode,
  });

  final TreatmentManagementStatus status;
  final TreatmentDetail? detail;
  final Medication? medication;
  final int? activeMedicationCount;
  final bool busy;
  final TreatmentManagementNotice? notice;
  final String? errorCode;

  bool get medicationUnavailable =>
      detail?.configured == true &&
      !(detail?.isDraft ?? true) &&
      medication == null;

  bool get medicationInactive =>
      medication?.active == false || medicationUnavailable;

  /// Only a configured, non-draft treatment can be paused, resumed or edited.
  bool get manageable =>
      detail?.configured == true &&
      !(detail?.isDraft ?? true) &&
      !medicationUnavailable;

  TreatmentManagementState copyWith({
    TreatmentManagementStatus? status,
    TreatmentDetail? detail,
    Medication? medication,
    int? activeMedicationCount,
    bool? busy,
    TreatmentManagementNotice? notice,
    String? errorCode,
  }) => TreatmentManagementState(
    status: status ?? this.status,
    detail: detail ?? this.detail,
    medication: medication ?? this.medication,
    activeMedicationCount: activeMedicationCount ?? this.activeMedicationCount,
    busy: busy ?? this.busy,
    notice: notice,
    errorCode: errorCode,
  );
}
