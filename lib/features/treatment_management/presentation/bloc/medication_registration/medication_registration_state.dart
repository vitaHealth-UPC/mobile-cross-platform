import '../../../domain/entities/medication.dart';

enum MedicationRegistrationStatus { idle, submitting, registered, failure }

/// Result of one registration attempt; the medication exists only after acknowledgement.
final class MedicationRegistrationState {
  const MedicationRegistrationState({
    this.status = MedicationRegistrationStatus.idle,
    this.medication,
    this.errorCode,
  });

  final MedicationRegistrationStatus status;
  final Medication? medication;
  final String? errorCode;
}
