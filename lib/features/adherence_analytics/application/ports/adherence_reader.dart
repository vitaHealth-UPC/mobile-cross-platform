import '../../../../shared/common/result/app_result.dart';
import '../readmodels/adherence_summary.dart';

/// Reads the adherence summary of one older adult for the captured session.
abstract interface class AdherenceReader {
  /// Returns the summary of the last [periodDays] days. A null success means
  /// the period has no definitive intakes ("insufficient data"), not an error.
  Future<AppResult<AdherenceSummary?>> summary(
    String olderAdultId,
    int periodDays,
  );
}
