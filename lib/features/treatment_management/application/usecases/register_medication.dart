import '../../../../shared/common/result/app_result.dart';
import '../../domain/entities/medication.dart';
import '../../domain/repositories/treatment_repository.dart';
import '../policies/medication_fields.dart';

/// Validates required fields before registering a medication for a linked adult.
final class RegisterMedication {
  const RegisterMedication(this._repository);
  final TreatmentRepository _repository;

  Future<AppResult<Medication>> call(
    String olderAdultId,
    String name,
    String presentation,
  ) {
    if (olderAdultId.trim().isEmpty ||
        name.trim().isEmpty ||
        presentation.trim().isEmpty) {
      return Future.value(const AppFailure('REQUIRED_FIELDS_MISSING'));
    }
    if (medicationFieldsTooLong(name, presentation)) {
      return Future.value(const AppFailure('MEDICATION_DETAILS_TOO_LONG'));
    }
    return _repository.registerMedication(
      olderAdultId.trim(),
      name.trim(),
      presentation.trim(),
    );
  }
}
