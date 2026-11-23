import '../../domain/entities/medication.dart';

/// Acknowledged medication and optional text to review in the treatment wizard.
/// Frequency and instructions are not persisted by medication registration.
final class MedicationRegistrationResult {
  const MedicationRegistrationResult({
    required this.medication,
    this.frequency = '',
    this.instructions = '',
  });
  final Medication medication;
  final String frequency;
  final String instructions;
}
