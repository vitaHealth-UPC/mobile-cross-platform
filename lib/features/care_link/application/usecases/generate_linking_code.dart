import '../../../../shared/common/result/app_result.dart';
import '../../domain/entities/care_link.dart';
import '../ports/care_link_writer.dart';

/// Requests evidence for an existing adult without impersonating adult consent.
final class GenerateLinkingCode {
  const GenerateLinkingCode(this._writer);
  final CareLinkWriter _writer;

  Future<AppResult<CareLink>> call(String olderAdultId) async {
    if (olderAdultId.isEmpty || olderAdultId != olderAdultId.trim()) {
      return const AppFailure('INVALID_PROFILE');
    }
    return _writer.generateCode(olderAdultId);
  }
}
