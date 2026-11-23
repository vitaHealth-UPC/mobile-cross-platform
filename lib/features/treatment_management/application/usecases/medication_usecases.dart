import '../../../../shared/common/result/app_result.dart';
import '../../domain/entities/medication.dart';
import '../../domain/repositories/treatment_repositories.dart';

bool _blank(String value) => value.trim().isEmpty;

/// Validates required fields before registering a medication for a linked adult.
final class RegisterMedication {
  const RegisterMedication(this._repository);
  final TreatmentRepository _repository;

  Future<AppResult<Medication>> call(
    String olderAdultId,
    String name,
    String presentation,
  ) {
    if (_blank(olderAdultId) || _blank(name) || _blank(presentation)) {
      return Future.value(const AppFailure('REQUIRED_FIELDS_MISSING'));
    }
    return _repository.registerMedication(
      olderAdultId.trim(),
      name.trim(),
      presentation.trim(),
    );
  }
}

/// Lists the medications of a linked adult, inactive ones included.
final class ListMedications {
  const ListMedications(this._repository);
  final MedicationManagementRepository _repository;

  Future<AppResult<List<Medication>>> call(String olderAdultId) {
    if (_blank(olderAdultId)) {
      return Future.value(const AppFailure('INVALID_OLDER_ADULT_REFERENCE'));
    }
    return _repository.list(olderAdultId.trim());
  }
}

/// Validates identity and replacement details before saving a medication.
final class UpdateMedication {
  const UpdateMedication(this._repository);
  final MedicationManagementRepository _repository;

  Future<AppResult<Medication>> call(
    String medicationId,
    String name,
    String presentation,
  ) {
    if (_blank(medicationId)) {
      return Future.value(const AppFailure('INVALID_MEDICATION_REFERENCE'));
    }
    if (_blank(name) || _blank(presentation)) {
      return Future.value(const AppFailure('REQUIRED_FIELDS_MISSING'));
    }
    return _repository.update(
      medicationId.trim(),
      name.trim(),
      presentation.trim(),
    );
  }
}

/// Stops a medication from producing new intakes while keeping its history.
final class DeactivateMedication {
  const DeactivateMedication(this._repository);
  final MedicationManagementRepository _repository;

  Future<AppResult<Medication>> call(String medicationId) =>
      _blank(medicationId)
      ? Future.value(const AppFailure('INVALID_MEDICATION_REFERENCE'))
      : _repository.deactivate(medicationId.trim());
}

/// Restores availability without automatically resuming any treatment.
final class ReactivateMedication {
  const ReactivateMedication(this._repository);
  final MedicationManagementRepository _repository;

  Future<AppResult<Medication>> call(String medicationId) =>
      _blank(medicationId)
      ? Future.value(const AppFailure('INVALID_MEDICATION_REFERENCE'))
      : _repository.reactivate(medicationId.trim());
}
