import '../../../../shared/common/result/app_result.dart';
import '../entities/medication.dart';
import '../entities/treatment.dart';

/// Registers medications and creates treatment drafts for a linked adult.
/// The acting caregiver is always the captured session, never a caller argument.
abstract interface class TreatmentRepository {
  Future<AppResult<Medication>> registerMedication(
    String olderAdultId,
    String name,
    String presentation,
  );

  /// Creates a draft; [planId] adds it as another medication of that treatment.
  Future<AppResult<Treatment>> createTreatment(
    String olderAdultId,
    String name, {
    String? planId,
  });
}
