import '../../../../shared/common/result/app_result.dart';
import '../../domain/entities/care_link.dart';
import '../readmodels/older_adult_profile.dart';

/// Caregiver-owned profile setup; actor identity comes from the session adapter.
abstract interface class CareLinkWriter {
  /// Registers a profile without granting care consent or adult access.
  Future<AppResult<OlderAdultProfile>> registerOlderAdult(
    String fullName,
    DateTime birthDate,
  );

  /// Issues temporary linking evidence for an adult owned by the caregiver.
  Future<AppResult<CareLink>> generateCode(String olderAdultId);
}
