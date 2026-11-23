import '../../../../shared/common/result/app_result.dart';
import '../../domain/entities/treatment.dart';
import '../../domain/repositories/treatment_lifecycle_repository.dart';

/// Lifecycle transition requested for a treatment.
enum TreatmentLifecycleAction { activate, pause, resume }

/// Validates the treatment reference and dispatches the requested transition.
final class ChangeTreatmentStatus {
  const ChangeTreatmentStatus(this._repository);
  final TreatmentLifecycleRepository _repository;

  Future<AppResult<Treatment>> call(
    String treatmentId,
    TreatmentLifecycleAction action,
  ) {
    if (treatmentId.trim().isEmpty) {
      return Future.value(const AppFailure('INVALID_TREATMENT_REFERENCE'));
    }
    final id = treatmentId.trim();
    return switch (action) {
      TreatmentLifecycleAction.activate => _repository.activate(id),
      TreatmentLifecycleAction.pause => _repository.pause(id),
      TreatmentLifecycleAction.resume => _repository.resume(id),
    };
  }
}
