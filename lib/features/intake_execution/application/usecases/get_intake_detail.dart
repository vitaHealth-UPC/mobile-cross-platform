import '../../../../shared/common/result/app_result.dart';
import '../../domain/entities/intake.dart';
import '../ports/intake_reader.dart';

/// Reads one intake; a blank reference never reaches the server.
final class GetIntakeDetail {
  const GetIntakeDetail(this._reader);
  final IntakeReader _reader;

  Future<AppResult<Intake>> call(String intakeId) async {
    if (intakeId.trim().isEmpty) return const AppFailure('INVALID_INTAKE');
    return _reader.detail(intakeId);
  }
}
