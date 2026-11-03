import '../../../../shared/common/result/app_result.dart';
import '../readmodels/older_adult_profile.dart';

/// Reads the profile of the adult bound to the captured full adult session.
abstract interface class AdultProfileReader {
  Future<AppResult<OlderAdultProfile>> readOwn();
}
