import '../../../../shared/common/result/app_result.dart';
import '../../domain/entities/medication.dart';
import '../../domain/repositories/medication_management_repository.dart';

/// Lists the medications of a linked adult, inactive ones included.
final class ListMedications {
  const ListMedications(this._repository);
  final MedicationManagementRepository _repository;

  Future<AppResult<List<Medication>>> call(String olderAdultId) {
    if (olderAdultId.trim().isEmpty) {
      return Future.value(const AppFailure('INVALID_OLDER_ADULT_REFERENCE'));
    }
    return _repository.list(olderAdultId.trim());
  }
}
