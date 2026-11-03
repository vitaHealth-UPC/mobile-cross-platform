import '../../../../shared/common/result/app_result.dart';
import '../../domain/repositories/session_repository.dart';

/// Requests session invalidation and server revocation through the repository.
final class SignOut {
  const SignOut(this._repository);
  final SessionRepository _repository;

  Future<AppResult<void>> call() => _repository.signOut();
}
