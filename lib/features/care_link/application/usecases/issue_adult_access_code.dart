import '../../../../shared/common/result/app_result.dart';
import '../ports/care_link_writer.dart';
import '../readmodels/adult_access_code.dart';

/// New single-use code so the adult can sign in on a new or reinstalled phone.
final class IssueAdultAccessCode {
  const IssueAdultAccessCode(this._writer);
  final CareLinkWriter _writer;

  Future<AppResult<AdultAccessCode>> call(String careLinkId) async {
    if (careLinkId.isEmpty || careLinkId != careLinkId.trim()) {
      return const AppFailure('INVALID_PROFILE');
    }
    return _writer.issueAccessCode(careLinkId);
  }
}
