/// Wizard steps, in order. `schedule` is kept for restored wizards; the
/// regimen step now holds dose, frequency and times together.
enum TreatmentSetupStep { details, regimen, schedule, reminders, review }

/// A medication included in the treatment, with the label shown to the user.
final class SetupMedication {
  const SetupMedication(this.id, this.label);
  final String id;
  final String label;

  @override
  bool operator ==(Object other) => other is SetupMedication && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// Validated regimen text of one medication.
final class SetupRegimen {
  const SetupRegimen({
    this.dose = '',
    this.frequency = '',
    this.scheduleText = '',
    this.instructions = '',
  });
  final String dose;
  final String frequency;

  /// Normalized times joined by commas, for example `08:00,20:00`.
  final String scheduleText;
  final String instructions;

  List<String> get scheduledTimes =>
      scheduleText.isEmpty ? const [] : scheduleText.split(',');
}

/// Everything validated so far plus the state of the current operation.
/// One treatment may hold several medications; each gets its own regimen and
/// its own server draft, all sharing one plan identity.
final class TreatmentSetupState {
  const TreatmentSetupState({
    this.step = TreatmentSetupStep.details,
    this.treatmentName = '',
    this.medications = const [],
    this.regimens = const {},
    this.treatmentIds = const {},
    this.activatedIds = const {},
    this.planId,
    this.followUpDelayMinutes,
    this.loading = false,
    this.activated = false,
    this.configurationIncomplete = false,
    this.errorCode,
    this.errorMedicationId,
  });

  final TreatmentSetupStep step;
  final String treatmentName;
  final List<SetupMedication> medications;

  /// Validated regimen by medication id.
  final Map<String, SetupRegimen> regimens;

  /// Server drafts already created, by medication id; reused on retry.
  final Map<String, String> treatmentIds;

  /// Medications whose regimen the server already activated.
  final Set<String> activatedIds;

  /// Plan shared by the drafts; known once the first draft exists.
  final String? planId;
  final int? followUpDelayMinutes;
  final bool loading;
  final bool activated;

  /// True when the server rejected a regimen as incomplete or invalid.
  final bool configurationIncomplete;
  final String? errorCode;

  /// Medication whose regimen caused [errorCode], when it is regimen-specific.
  final String? errorMedicationId;

  SetupRegimen get _first => medications.isEmpty
      ? const SetupRegimen()
      : regimens[medications.first.id] ?? const SetupRegimen();

  /// Draft of the first medication (single-medication views and tests).
  String? get treatmentId =>
      medications.isEmpty ? null : treatmentIds[medications.first.id];
  String get dose => _first.dose;
  String get frequency => _first.frequency;
  String get scheduleText => _first.scheduleText;
  String get instructions => _first.instructions;
  List<String> get scheduledTimes => _first.scheduledTimes;

  TreatmentSetupState copyWith({
    TreatmentSetupStep? step,
    String? treatmentName,
    List<SetupMedication>? medications,
    Map<String, SetupRegimen>? regimens,
    Map<String, String>? treatmentIds,
    Set<String>? activatedIds,
    String? planId,
    int? followUpDelayMinutes,
    bool clearFollowUp = false,
    bool? loading,
    bool? activated,
    bool? configurationIncomplete,
    String? errorCode,
    String? errorMedicationId,
  }) => TreatmentSetupState(
    step: step ?? this.step,
    treatmentName: treatmentName ?? this.treatmentName,
    medications: medications ?? this.medications,
    regimens: regimens ?? this.regimens,
    treatmentIds: treatmentIds ?? this.treatmentIds,
    activatedIds: activatedIds ?? this.activatedIds,
    planId: planId ?? this.planId,
    followUpDelayMinutes: clearFollowUp
        ? null
        : followUpDelayMinutes ?? this.followUpDelayMinutes,
    loading: loading ?? this.loading,
    activated: activated ?? this.activated,
    configurationIncomplete:
        configurationIncomplete ?? this.configurationIncomplete,
    errorCode: errorCode,
    errorMedicationId: errorMedicationId,
  );
}
