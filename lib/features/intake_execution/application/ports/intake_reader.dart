import '../../../../shared/common/result/app_result.dart';
import '../../domain/entities/intake.dart';

/// Reads the intakes of the adult bound to the captured adult session.
abstract interface class IntakeReader {
  /// Returns the next pending intake; a null success means none is pending.
  Future<AppResult<Intake?>> next();

  /// Returns intakes scheduled in the half-open UTC interval [from, to).
  Future<AppResult<List<Intake>>> agenda(DateTime from, DateTime to);

  /// Returns the stored evidence of one intake of the session adult.
  Future<AppResult<Intake>> detail(String intakeId);
}
