import '../../../../shared/common/result/app_result.dart';
import '../../domain/entities/medication.dart';
import '../../domain/repositories/medication_management_repository.dart';

/// Restores availability without automatically resuming any treatment.
final class ReactivateMedication {
  const ReactivateMedication(this._repository);
  final MedicationManagementRepository _repository;

  Future<AppResult<Medication>> call(String medicationId) =>
      medicationId.trim().isEmpty
      ? Future.value(const AppFailure('INVALID_MEDICATION_REFERENCE'))
      : _repository.reactivate(medicationId.trim());
}
