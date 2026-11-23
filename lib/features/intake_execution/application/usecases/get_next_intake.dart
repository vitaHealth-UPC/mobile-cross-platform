import '../../../../shared/common/result/app_result.dart';
import '../../domain/entities/intake.dart';
import '../ports/intake_reader.dart';

/// Reads the next pending intake; absence is a legitimate empty result.
final class GetNextIntake {
  const GetNextIntake(this._reader);
  final IntakeReader _reader;

  Future<AppResult<Intake?>> call() => _reader.next();
}
