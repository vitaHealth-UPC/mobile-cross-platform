import '../../../../shared/common/result/app_result.dart';
import '../entities/medication.dart';
import '../entities/treatment.dart';
import '../value_objects/treatment_regimen.dart';

/// Registers medications and creates treatment drafts for a linked adult.
/// The acting caregiver is always the captured session, never a caller argument.
abstract interface class TreatmentRepository {
  Future<AppResult<Medication>> registerMedication(
    String olderAdultId,
    String name,
    String presentation,
  );

  Future<AppResult<Treatment>> createTreatment(
    String olderAdultId,
    String name,
  );
}

/// Lists and maintains medications without removing their recorded history.
abstract interface class MedicationManagementRepository {
  /// Ordered by name by the backend, inactive medications included.
  Future<AppResult<List<Medication>>> list(String olderAdultId);

  Future<AppResult<Medication>> update(
    String medicationId,
    String name,
    String presentation,
  );

  /// The medication keeps its history; it just stops producing new intakes.
  Future<AppResult<Medication>> deactivate(String medicationId);

  /// Restores availability without resuming any treatment.
  Future<AppResult<Medication>> reactivate(String medicationId);
}

/// Persists regimen configuration and treatment lifecycle transitions.
abstract interface class TreatmentLifecycleRepository {
  Future<AppResult<Treatment>> configure(
    String treatmentId,
    String medicationId,
    TreatmentRegimen regimen,
  );

  Future<AppResult<Treatment>> activate(String treatmentId);

  Future<AppResult<Treatment>> pause(String treatmentId);

  Future<AppResult<Treatment>> resume(String treatmentId);
}
