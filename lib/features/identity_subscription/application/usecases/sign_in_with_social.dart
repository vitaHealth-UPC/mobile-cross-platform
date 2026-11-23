import '../../../../shared/common/result/app_result.dart';
import '../../domain/entities/account_session.dart';
import '../../domain/repositories/social_session_repository.dart';
import '../../domain/value_objects/social_provider.dart';

/// Keeps provider SDKs and credential exchange outside presentation state.
final class SignInWithSocial {
  const SignInWithSocial(this._repository);
  final SocialSessionRepository _repository;

  Future<AppResult<AccountSession?>> call(SocialProvider provider) =>
      _repository.signIn(provider);
}
