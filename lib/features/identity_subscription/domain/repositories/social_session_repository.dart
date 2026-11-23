import '../../../../shared/common/result/app_result.dart';
import '../entities/account_session.dart';
import '../value_objects/social_provider.dart';

/// Authenticates a caregiver through a provider and the authoritative Tata API.
abstract interface class SocialSessionRepository {
  /// Null success means the provider flow was cancelled without changing access.
  Future<AppResult<AccountSession?>> signIn(SocialProvider provider);
}
