import '../../../../shared/common/result/app_result.dart';
import '../../domain/repositories/session_repository.dart';

/// Requests session invalidation and server revocation through the repository.
final class SignOut {
  const SignOut(this._repository, {this.beforeSignOut});
  final SessionRepository _repository;

  /// Removes authenticated device integrations before their credential is discarded.
  final Future<void> Function()? beforeSignOut;

  Future<AppResult<void>> call() async {
    try {
      await beforeSignOut?.call();
    } on Exception {
      // An unavailable device integration must not prevent account revocation.
    }
    return _repository.signOut();
  }
}
