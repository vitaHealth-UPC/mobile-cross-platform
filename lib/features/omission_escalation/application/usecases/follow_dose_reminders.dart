import '../../../../shared/common/result/app_result.dart';
import '../failure_codes.dart';
import '../ports/push_target_store.dart';

/// The older adult signed in on this device and wants the reinforced reminders of their
/// intakes. Remembers the display target without subscribing to public clinical topics.
final class FollowDoseReminders {
  const FollowDoseReminders(this._store);
  final PushTargetStore _store;

  Future<AppResult<void>> call({
    required String olderAdultId,
    required String olderAdultName,
  }) async {
    final adult = olderAdultId.trim();
    if (adult.isEmpty) return const AppFailure(invalidFollowUpReference);
    await _store.rememberOlderAdult(adult, olderAdultName.trim());
    return const AppSuccess(null);
  }
}
