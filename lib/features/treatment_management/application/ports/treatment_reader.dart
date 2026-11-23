import '../../../../shared/common/result/app_result.dart';
import '../readmodels/treatment_detail.dart';

/// Reads treatments for an authorized caregiver; the caregiver is the captured session.
abstract interface class TreatmentReader {
  /// Treatments of one linked adult, oldest first.
  Future<AppResult<List<TreatmentDetail>>> list(String olderAdultId);

  /// One treatment with its configured regimen, if any.
  Future<AppResult<TreatmentDetail>> detail(String treatmentId);
}
