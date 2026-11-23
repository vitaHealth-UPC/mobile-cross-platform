import '../../../../shared/common/result/app_result.dart';
import '../../domain/value_objects/regimen_text.dart';

/// Validated dose and frequency selected together in the regimen wizard.
final class RegimenBasics {
  const RegimenBasics(this.dose, this.frequency);
  final Dosage dose;
  final Frequency frequency;
}

/// Parses dose and frequency into the values used by the regimen wizard.
final class SetDoseFrequency {
  const SetDoseFrequency();

  AppResult<RegimenBasics> call(String dose, String frequency) {
    final parsedDose = Dosage.tryParse(dose);
    if (parsedDose == null) return const AppFailure('INVALID_DOSAGE');
    final parsedFrequency = Frequency.tryParse(frequency);
    if (parsedFrequency == null) return const AppFailure('INVALID_FREQUENCY');
    return AppSuccess(RegimenBasics(parsedDose, parsedFrequency));
  }
}
