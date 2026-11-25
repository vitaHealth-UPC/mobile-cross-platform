import '../../../../shared/common/result/app_result.dart';
import '../ports/care_link_writer.dart';

/// The caregiver stops caring for an adult: their own link ends, other
/// caregivers keep theirs and the adult's history stays on the server.
final class EndCareLink {
  const EndCareLink(this._writer);
  final CareLinkWriter _writer;

  Future<AppResult<void>> call(String careLinkId) async {
    if (careLinkId.isEmpty || careLinkId != careLinkId.trim()) {
      return const AppFailure('INVALID_PROFILE');
    }
    return _writer.endLink(careLinkId);
  }
}
