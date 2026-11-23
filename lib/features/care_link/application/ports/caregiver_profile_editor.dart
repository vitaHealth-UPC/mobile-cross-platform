import '../../../../shared/common/result/app_result.dart';
import '../readmodels/older_adult_profile.dart';

/// Reads and edits a profile owned by the authenticated caregiver.
/// Neither operation can reassign the registration owner or care consent.
abstract interface class CaregiverProfileEditor {
  Future<AppResult<OlderAdultProfile>> readProfile(String olderAdultId);

  Future<AppResult<OlderAdultProfile>> updateProfile(
    String olderAdultId,
    String fullName,
    DateTime birthDate,
  );
}
