import '../../../../shared/common/result/app_result.dart';
import '../readmodels/caregiver_link_summary.dart';

/// Reads relationships authorized for the currently captured caregiver session.
abstract interface class CaregiverProfilesReader {
  /// Returns consented relationships; an empty success is a legitimate result.
  Future<AppResult<List<CaregiverLinkSummary>>> readConfirmed();
}
