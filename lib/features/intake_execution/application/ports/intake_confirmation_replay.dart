import '../../../../shared/common/result/app_result.dart';
import '../readmodels/confirmation_receipt.dart';
import 'intake_confirmation.dart';

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
