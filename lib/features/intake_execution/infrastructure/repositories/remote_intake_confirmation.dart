import '../../../../shared/application/session/session_store.dart';
import '../../../../shared/common/result/app_result.dart';
import '../../application/ports/intake_confirmation.dart';
import '../../application/readmodels/confirmation_receipt.dart';
import '../mappers/intake_mapper.dart';
import '../remote/intake_api.dart';
import 'adult_session_request.dart';

/// Sends touch confirmations with the adult session and validates the receipt.
/// A receipt is accepted only for the same intake and adult, already taken.
final class RemoteIntakeConfirmation implements IntakeConfirmation {
  const RemoteIntakeConfirmation({required this._api, required this._store});

  final IntakeApi _api;
  final SessionStore _store;

  @override
  Future<AppResult<ConfirmationReceipt>> confirm(String intakeId) =>
      adultSessionRequest(
        _store,
        (session) => _api.confirm(intakeId, session.accessToken),
        (response, owner) {
          final body = response.body;
          final code = body is Map<String, dynamic> ? body['title'] : null;
          if (response.status == 409 && code == 'INTAKE_NOT_CONFIRMABLE') {
            return const AppFailure('INTAKE_NOT_CONFIRMABLE');
          }
          if (response.status == 404) {
            return const AppFailure('INTAKE_NOT_FOUND');
          }
          if (response.status != 200) {
            return const AppFailure('REQUEST_FAILED');
          }
          final receipt = IntakeMapper.receipt(body);
          return receipt.intake.id == intakeId &&
                  receipt.intake.olderAdultId == owner.id &&
                  receipt.intake.taken
              ? AppSuccess(receipt)
              : const AppFailure('INVALID_RESPONSE');
        },
      );
}
