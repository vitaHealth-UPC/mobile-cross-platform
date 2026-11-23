import '../../../../shared/common/result/app_result.dart';
import '../readmodels/contact_option.dart';

/// Resolves the contact channel and display name as one follow-up operation.
abstract interface class ContactOptionReader {
  Future<AppResult<ContactOption>> call(String olderAdultId);
}
