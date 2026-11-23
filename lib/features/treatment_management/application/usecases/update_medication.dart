import '../../../../shared/common/result/app_result.dart';
import '../../domain/entities/medication.dart';
import '../../domain/repositories/medication_management_repository.dart';
import '../policies/medication_fields.dart';

/// Validates identity and replacement details before saving a medication.
final class UpdateMedication {
  const UpdateMedication(this._repository);
  final MedicationManagementRepository _repository;

  Future<AppResult<Medication>> call(
    String medicationId,
    String name,
    String presentation,
  ) {
    if (medicationId.trim().isEmpty) {
      return Future.value(const AppFailure('INVALID_MEDICATION_REFERENCE'));
    }
    if (name.trim().isEmpty || presentation.trim().isEmpty) {
      return Future.value(const AppFailure('REQUIRED_FIELDS_MISSING'));
    }
    if (medicationFieldsTooLong(name, presentation)) {
      return Future.value(const AppFailure('MEDICATION_DETAILS_TOO_LONG'));
    }
    return _repository.update(
      medicationId.trim(),
      name.trim(),
      presentation.trim(),
    );
  }
}
