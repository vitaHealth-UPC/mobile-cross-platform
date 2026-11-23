/// Wizard steps, in order. The first step creates the draft on the server.
enum TreatmentSetupStep { details, regimen, schedule, reminders, review }

/// Everything validated so far plus the state of the current operation.
final class TreatmentSetupState {
  const TreatmentSetupState({
    this.step = TreatmentSetupStep.details,
    this.treatmentId,
    this.treatmentName = '',
    this.dose = '',
    this.frequency = '',
    this.scheduleText = '',
    this.instructions = '',
    this.followUpDelayMinutes,
    this.loading = false,
    this.activated = false,
    this.configurationIncomplete = false,
    this.errorCode,
  });

  final TreatmentSetupStep step;

  /// Server identity of the draft; null until the first step is acknowledged.
  final String? treatmentId;
  final String treatmentName;
  final String dose;
  final String frequency;

  /// Normalized times joined by commas, for example `08:00,20:00`.
  final String scheduleText;
  final String instructions;
  final int? followUpDelayMinutes;
  final bool loading;
  final bool activated;

  /// True when the server rejected the regimen as incomplete or invalid.
  final bool configurationIncomplete;
  final String? errorCode;

  List<String> get scheduledTimes =>
      scheduleText.isEmpty ? const [] : scheduleText.split(',');

  TreatmentSetupState copyWith({
    TreatmentSetupStep? step,
    String? treatmentId,
    String? treatmentName,
    String? dose,
    String? frequency,
    String? scheduleText,
    String? instructions,
    int? followUpDelayMinutes,
    bool clearFollowUp = false,
    bool? loading,
    bool? activated,
    bool? configurationIncomplete,
    String? errorCode,
  }) => TreatmentSetupState(
    step: step ?? this.step,
    treatmentId: treatmentId ?? this.treatmentId,
    treatmentName: treatmentName ?? this.treatmentName,
    dose: dose ?? this.dose,
    frequency: frequency ?? this.frequency,
    scheduleText: scheduleText ?? this.scheduleText,
    instructions: instructions ?? this.instructions,
    followUpDelayMinutes: clearFollowUp
        ? null
        : followUpDelayMinutes ?? this.followUpDelayMinutes,
    loading: loading ?? this.loading,
    activated: activated ?? this.activated,
    configurationIncomplete:
        configurationIncomplete ?? this.configurationIncomplete,
    errorCode: errorCode,
  );
}
