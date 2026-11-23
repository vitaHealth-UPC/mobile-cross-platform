import '../../../../shared/application/time/clock.dart';
import '../../../../shared/common/result/app_result.dart';
import '../ports/care_link_writer.dart';
import '../readmodels/older_adult_profile.dart';

/// Validates profile input and preserves a calendar birth date before registration.
final class RegisterOlderAdult {
  const RegisterOlderAdult(this._writer, this._clock);
  final CareLinkWriter _writer;
  final Clock _clock;

  Future<AppResult<OlderAdultProfile>> call(
    String fullName,
    DateTime birthDate,
  ) async {
    final name = fullName.trim();
    if (name.isEmpty || name.length > 160) {
      return const AppFailure('INVALID_NAME');
    }
    final date = DateTime.utc(birthDate.year, birthDate.month, birthDate.day);
    final now = _clock().toUtc();
    if (date.isAfter(DateTime.utc(now.year, now.month, now.day))) {
      return const AppFailure('INVALID_BIRTH_DATE');
    }
    return _writer.registerOlderAdult(name, date);
  }
}
