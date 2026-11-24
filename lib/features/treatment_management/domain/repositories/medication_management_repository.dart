import '../../../../shared/common/result/app_result.dart';
import '../entities/medication.dart';

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

  /// Removes a medication from the catalog, preserving its history.
  Future<AppResult<void>> delete(String medicationId);

  /// Restores availability without resuming any treatment.
  Future<AppResult<Medication>> reactivate(String medicationId);
}
