import '../../../../shared/common/result/app_result.dart';
import '../../domain/entities/treatment.dart';
import '../../domain/repositories/treatment_repository.dart';
import '../../domain/value_objects/treatment_status.dart';

/// Creates a named draft; the saved treatment must remain a draft until it is configured.
final class CreateTreatment {
  const CreateTreatment(this._repository);
  final TreatmentRepository _repository;

  Future<AppResult<Treatment>> call(
    String olderAdultId,
    String name, {
    String? planId,
  }) async {
    if (olderAdultId.trim().isEmpty || name.trim().isEmpty) {
      return const AppFailure('REQUIRED_FIELDS_MISSING');
    }
    final result = await _repository.createTreatment(
      olderAdultId.trim(),
      name.trim(),
      planId: planId,
    );
    return switch (result) {
      AppSuccess<Treatment>(:final value)
          when value.status != TreatmentStatus.draft =>
        const AppFailure('INVALID_INITIAL_TREATMENT_STATE'),
      _ => result,
    };
  }
}
