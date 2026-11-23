import '../../domain/value_objects/omission_push.dart';
import '../policies/omission_push_access_policy.dart';
import '../ports/omission_notifier.dart';

/// Shows a received push only while the signed-in owner is its recipient.
/// Returns whether the notice was shown.
final class HandleIncomingOmissionPush {
  const HandleIncomingOmissionPush(this._policy, this._notifier);
  final OmissionPushAccessPolicy _policy;
  final OmissionNotifier _notifier;

  Future<bool> call(OmissionPush push) async {
    if (!await _policy.allows(push)) return false;
    await _notifier.show(push);
    return true;
  }
}
