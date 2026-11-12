import '../../../application/readmodels/treatment_readmodels.dart';
import '../../../domain/entities/medication.dart';

enum TreatmentManagementStatus { loading, ready, failure }

/// Treatment, its medication and the state of the current operation.
final class TreatmentManagementState {
  const TreatmentManagementState({
    this.status = TreatmentManagementStatus.loading,
    this.detail,
    this.medication,
    this.activeMedicationCount,
    this.busy = false,
    this.regimenSaved = false,
    this.errorCode,
  });

  final TreatmentManagementStatus status;
  final TreatmentDetail? detail;
  final Medication? medication;
  final int? activeMedicationCount;
  final bool busy;
  final bool regimenSaved;
  final String? errorCode;

  bool get medicationInactive => medication?.active == false;

  /// Only a configured, non-draft treatment can be paused, resumed or edited.
  bool get manageable =>
      detail?.configured == true && !(detail?.isDraft ?? true);

  TreatmentManagementState copyWith({
    TreatmentManagementStatus? status,
    TreatmentDetail? detail,
    Medication? medication,
    int? activeMedicationCount,
    bool? busy,
    bool? regimenSaved,
    String? errorCode,
  }) => TreatmentManagementState(
    status: status ?? this.status,
    detail: detail ?? this.detail,
    medication: medication ?? this.medication,
    activeMedicationCount: activeMedicationCount ?? this.activeMedicationCount,
    busy: busy ?? this.busy,
    regimenSaved: regimenSaved ?? false,
    errorCode: errorCode,
  );
}
