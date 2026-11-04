import '../../../../shared/common/result/app_result.dart';
import '../ports/intake_confirmation.dart';
import '../readmodels/confirmation_receipt.dart';

/// Confirms an intake by touch (US-06); timing and outcome are server decisions.
final class ConfirmIntake {
  const ConfirmIntake(this._confirmation);
  final IntakeConfirmation _confirmation;

  Future<AppResult<ConfirmationReceipt>> call(String intakeId) async {
    if (intakeId.trim().isEmpty) return const AppFailure('INVALID_INTAKE');
    return _confirmation.confirm(intakeId);
  }
}
