import '../../../../shared/common/result/app_result.dart';
import '../entities/treatment.dart';
import '../value_objects/treatment_regimen.dart';

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
