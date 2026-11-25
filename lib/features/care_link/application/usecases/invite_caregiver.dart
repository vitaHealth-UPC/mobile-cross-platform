import '../../../../shared/common/result/app_result.dart';
import '../ports/care_link_writer.dart';
import '../readmodels/adult_access_code.dart';

/// Code another caregiver uses to request caring for the same adult.
final class InviteCaregiver {
  const InviteCaregiver(this._writer);
  final CareLinkWriter _writer;

  Future<AppResult<AdultAccessCode>> call(String careLinkId) =>
      careLinkId.trim().isEmpty
      ? Future.value(const AppFailure('INVALID_PROFILE'))
      : _writer.inviteCaregiver(careLinkId);
}
