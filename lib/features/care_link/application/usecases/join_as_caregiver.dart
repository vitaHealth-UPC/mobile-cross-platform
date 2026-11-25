import '../../../../shared/common/result/app_result.dart';
import '../../domain/value_objects/access_code_text.dart';
import '../ports/care_link_writer.dart';

/// Requests caring for an adult with another caregiver's code; the adult
/// accepts or declines it from their own phone.
final class JoinAsCaregiver {
  const JoinAsCaregiver(this._writer);
  final CareLinkWriter _writer;

  Future<AppResult<void>> call(String code) async {
    final normalized = AccessCodeText.tryParse(code);
    if (normalized == null) return const AppFailure('INVALID_LINKING_CODE');
    return _writer.joinAsCaregiver(normalized);
  }
}
