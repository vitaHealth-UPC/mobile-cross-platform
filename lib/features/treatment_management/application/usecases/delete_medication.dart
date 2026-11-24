import '../../../../shared/common/result/app_result.dart';
import '../../domain/repositories/medication_management_repository.dart';

/// Removes a medication from the catalog while preserving its history.
final class DeleteMedication {
  const DeleteMedication(this._repository);
  final MedicationManagementRepository _repository;

  Future<AppResult<void>> call(String medicationId) =>
      medicationId.trim().isEmpty
      ? Future.value(const AppFailure('INVALID_MEDICATION_REFERENCE'))
      : _repository.delete(medicationId.trim());
}
