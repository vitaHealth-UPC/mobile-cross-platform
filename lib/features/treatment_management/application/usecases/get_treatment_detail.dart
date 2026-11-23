import '../../../../shared/common/result/app_result.dart';
import '../ports/treatment_reader.dart';
import '../readmodels/treatment_detail.dart';

/// Reads one treatment and its configured regimen.
final class GetTreatmentDetail {
  const GetTreatmentDetail(this._reader);
  final TreatmentReader _reader;

  Future<AppResult<TreatmentDetail>> call(String treatmentId) =>
      treatmentId.trim().isEmpty
      ? Future.value(const AppFailure('INVALID_TREATMENT_REFERENCE'))
      : _reader.detail(treatmentId.trim());
}
