import '../../domain/entities/medication.dart';

/// Acknowledged medication and optional text to review in the treatment wizard.
/// Frequency and instructions are not persisted by medication registration.
final class MedicationRegistrationResult {
  const MedicationRegistrationResult({
    required this.medication,
    this.frequency = '',
    this.instructions = '',
    this.initialStockSaved,
  });
  final Medication medication;
  final String frequency;
  final String instructions;

  /// Null when no initial stock was typed; false when the medication was saved
  /// but its stock could not be (the caregiver can add it from Inventory).
  final bool? initialStockSaved;
}
