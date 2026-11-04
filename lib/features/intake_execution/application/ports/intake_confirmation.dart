import '../../../../shared/common/result/app_result.dart';
import '../readmodels/confirmation_receipt.dart';

/// Records a manual (touch) confirmation; the server classifies it as on
/// time or late and replays an existing confirmation without duplicating it.
abstract interface class IntakeConfirmation {
  /// Fails with `INTAKE_NOT_CONFIRMABLE` when the intake is no longer pending
  /// and was not confirmed, for example after an omission.
  Future<AppResult<ConfirmationReceipt>> confirm(String intakeId);
}
