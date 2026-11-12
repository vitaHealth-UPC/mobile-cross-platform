import '../../../../shared/common/result/app_result.dart';
import '../readmodels/confirmation_receipt.dart';

/// Records a manual (touch) confirmation; the server classifies it as on
/// time or late and replays an existing confirmation without duplicating it.
abstract interface class IntakeConfirmation {
  /// Fails with `INTAKE_NOT_CONFIRMABLE` when the intake is no longer pending
  /// and was not confirmed, for example after an omission.
  Future<AppResult<ConfirmationReceipt>> confirm(String intakeId);
}

/// Delivers a confirmation saved on the device, reporting when it really
/// happened so the server can classify the original action.
abstract interface class IntakeConfirmationReplay
    implements IntakeConfirmation {
  /// Fails with `INVALID_CONFIRMATION_TIME` when the server rejects
  /// [confirmedAt], for example because the device clock is ahead.
  Future<AppResult<ConfirmationReceipt>> replay(
    String intakeId,
    DateTime confirmedAt,
  );
}
