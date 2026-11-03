import '../../../../shared/common/result/app_result.dart';
import '../../domain/entities/account_session.dart';
import '../../domain/repositories/session_repository.dart';

/// Validates stored access through the repository; absence is a successful anonymous result.
final class RestoreSession {
  const RestoreSession(this._repository);
  final SessionRepository _repository;

  Future<AppResult<AccountSession?>> call() => _repository.restore();
}
