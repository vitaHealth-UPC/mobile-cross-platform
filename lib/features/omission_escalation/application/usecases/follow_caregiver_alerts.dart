import '../../../../shared/common/result/app_result.dart';
import '../failure_codes.dart';
import '../ports/push_target_store.dart';

/// The caregiver opened the follow-up of an older adult and wants its missed-dose alerts.
/// Remembers a navigation target; clinical delivery uses authenticated device registration.
final class FollowCaregiverAlerts {
  const FollowCaregiverAlerts(this._store);
  final PushTargetStore _store;

  Future<AppResult<void>> call({
    required String caregiverId,
    required String olderAdultId,
  }) async {
    final caregiver = caregiverId.trim();
    final adult = olderAdultId.trim();
    if (caregiver.isEmpty || adult.isEmpty) {
      return const AppFailure(invalidFollowUpReference);
    }
    await _store.rememberCaregiver(adult, caregiver);
    return const AppSuccess(null);
  }
}
