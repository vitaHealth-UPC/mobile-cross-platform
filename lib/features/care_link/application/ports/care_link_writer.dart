import '../../../../shared/common/result/app_result.dart';
import '../../domain/entities/care_link.dart';
import '../readmodels/adult_access_code.dart';
import '../readmodels/older_adult_profile.dart';

/// Caregiver-owned profile setup; actor identity comes from the session adapter.
abstract interface class CareLinkWriter {
  /// Registers a profile without granting care consent or adult access.
  Future<AppResult<OlderAdultProfile>> registerOlderAdult(
    String fullName,
    DateTime birthDate,
  );

  /// Removes the person from the caregiver's family list (ends their own link).
  Future<AppResult<void>> endLink(String careLinkId);

  /// Issues a single-use sign-in code for the adult of a confirmed link.
  Future<AppResult<AdultAccessCode>> issueAccessCode(String careLinkId);

  /// Issues a code another caregiver uses to request caring for the adult.
  Future<AppResult<AdultAccessCode>> inviteCaregiver(String careLinkId);

  /// Requests caring for an adult with another caregiver's code.
  Future<AppResult<void>> joinAsCaregiver(String code);

  /// Issues temporary linking evidence for an adult owned by the caregiver.
  Future<AppResult<CareLink>> generateCode(String olderAdultId);
}
