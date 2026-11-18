import '../../../../shared/application/time/clock.dart';
import '../../../../shared/common/result/app_result.dart';
import '../ports/caregiver_profile_editor.dart';
import '../readmodels/older_adult_profile.dart';

/// Validates basic fields; birth dates remain calendar dates, not local instants.
final class UpdateCaregiverProfile {
  const UpdateCaregiverProfile(this._editor, this._clock);
  final CaregiverProfileEditor _editor;
  final Clock _clock;

  Future<AppResult<OlderAdultProfile>> call(
    String olderAdultId,
    String fullName,
    DateTime birthDate,
  ) async {
    if (olderAdultId.trim().isEmpty) {
      return const AppFailure('INVALID_REFERENCE');
    }
    final name = fullName.trim();
    if (name.isEmpty || name.length > 160) {
      return const AppFailure('INVALID_NAME');
    }
    final date = DateTime.utc(birthDate.year, birthDate.month, birthDate.day);
    final today = _clock();
    if (date.isAfter(DateTime.utc(today.year, today.month, today.day))) {
      return const AppFailure('INVALID_BIRTH_DATE');
    }
    return _editor.updateProfile(olderAdultId.trim(), name, date);
  }
}
