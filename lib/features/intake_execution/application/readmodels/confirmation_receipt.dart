import '../../domain/entities/intake.dart';

/// Server receipt of a confirmation request.
/// [alreadyConfirmed] marks an idempotent replay that created no new record.
final class ConfirmationReceipt {
  const ConfirmationReceipt({
    required this.intake,
    required this.alreadyConfirmed,
  });

  final Intake intake;
  final bool alreadyConfirmed;
}
