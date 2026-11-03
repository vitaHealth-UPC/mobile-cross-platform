import '../../../../shared/common/result/app_result.dart';

/// Recovery is anonymous and never creates or replaces an authenticated session.
abstract interface class PasswordRecovery {
  /// Accepts a uniform request receipt without revealing account existence.
  Future<AppResult<void>> request(String email);

  /// Replaces the password with a one-use [code]; success does not grant access.
  Future<AppResult<void>> complete(
    String email,
    String code,
    String newPassword,
  );
}
