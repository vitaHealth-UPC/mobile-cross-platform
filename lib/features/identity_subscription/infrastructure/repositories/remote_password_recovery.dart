import '../../../../shared/common/result/app_result.dart';
import '../../../../shared/infrastructure/network/api_response.dart';
import '../../application/ports/password_recovery.dart';
import '../mappers/identity_failure_mapper.dart';
import '../remote/password_recovery_api.dart';

/// Accepts exact recovery receipts without reading or creating a session.
/// Server failures are reduced to safe codes for localized presentation.
final class RemotePasswordRecovery implements PasswordRecovery {
  const RemotePasswordRecovery(this._api);
  final PasswordRecoveryApi _api;

  @override
  Future<AppResult<void>> request(String email) async {
    try {
      final response = await _api.request(email);
      return response.status == 202
          ? const AppSuccess(null)
          : identityFailure(response);
    } on ApiTransportException catch (error) {
      return AppFailure(error.code);
    }
  }

  @override
  Future<AppResult<void>> complete(
    String email,
    String code,
    String newPassword,
  ) async {
    try {
      final response = await _api.complete(email, code, newPassword);
      return response.status == 204
          ? const AppSuccess(null)
          : identityFailure(response);
    } on ApiTransportException catch (error) {
      return AppFailure(error.code);
    }
  }
}
