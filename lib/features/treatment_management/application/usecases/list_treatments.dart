import '../../../../shared/common/result/app_result.dart';
import '../ports/treatment_reader.dart';
import '../readmodels/treatment_detail.dart';

/// Reads the treatments of a linked adult.
final class ListTreatments {
  const ListTreatments(this._reader);
  final TreatmentReader _reader;

  Future<AppResult<List<TreatmentDetail>>> call(String olderAdultId) =>
      olderAdultId.trim().isEmpty
      ? Future.value(const AppFailure('INVALID_REFERENCE'))
      : _reader.list(olderAdultId.trim());
}
