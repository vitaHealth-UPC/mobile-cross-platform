import '../../../../shared/common/result/app_result.dart';
import '../../domain/entities/medication.dart';
import '../../domain/repositories/medication_management_repository.dart';

/// Stops a medication from producing new intakes while keeping its history.
final class DeactivateMedication {
  const DeactivateMedication(this._repository);
  final MedicationManagementRepository _repository;

  Future<AppResult<Medication>> call(String medicationId) =>
      medicationId.trim().isEmpty
      ? Future.value(const AppFailure('INVALID_MEDICATION_REFERENCE'))
      : _repository.deactivate(medicationId.trim());
}
