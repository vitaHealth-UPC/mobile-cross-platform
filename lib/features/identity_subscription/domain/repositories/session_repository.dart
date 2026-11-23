import '../../../../shared/common/result/app_result.dart';
import '../entities/account_session.dart';

/// Domain contract for password access, current-session validation and sign-out.
abstract interface class SessionRepository {
  /// Authenticates normalized [email] using the exact [password].
  /// Success exposes public metadata rather than the bearer credential.
  Future<AppResult<AccountSession>> signIn(String email, String password);

  /// Validates stored access remotely; null success means anonymous access.
  /// Network failure must not be treated as a valid cached session.
  Future<AppResult<AccountSession?>> restore();

  /// Invalidates local access and attempts to revoke the captured server session.
  /// A failure remains explicit even when local access has already been cleared.
  Future<AppResult<void>> signOut();
}
