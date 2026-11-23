import '../../../../shared/common/result/app_result.dart';
import '../ports/adherence_reader.dart';
import '../readmodels/adherence_summary.dart';

/// Loads adherence history inside the periods the backend supports.
final class GetAdherenceSummary {
  const GetAdherenceSummary(this._reader);

  final AdherenceReader _reader;

  /// Fails with `INVALID_OLDER_ADULT_REFERENCE` for a blank adult and with
  /// `INVALID_PERIOD` outside 1 to 31 days, before any request is made.
  Future<AppResult<AdherenceSummary?>> call(
    String olderAdultId,
    int periodDays,
  ) {
    final adult = olderAdultId.trim();
    if (adult.isEmpty) {
      return Future.value(const AppFailure('INVALID_OLDER_ADULT_REFERENCE'));
    }
    if (periodDays < 1 || periodDays > 31) {
      return Future.value(const AppFailure('INVALID_PERIOD'));
    }
    return _reader.summary(adult, periodDays);
  }
}
