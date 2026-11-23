/// Intents of the medication list: reload, edit, deactivate or reactivate.
sealed class MedicationManagementEvent {
  const MedicationManagementEvent();
}

final class MedicationsRequested extends MedicationManagementEvent {
  const MedicationsRequested();
}

final class MedicationEdited extends MedicationManagementEvent {
  const MedicationEdited(this.medicationId, this.name, this.presentation);
  final String medicationId;
  final String name;
  final String presentation;
}

final class MedicationDeactivated extends MedicationManagementEvent {
  const MedicationDeactivated(this.medicationId);
  final String medicationId;
}

final class MedicationReactivated extends MedicationManagementEvent {
  const MedicationReactivated(this.medicationId);
  final String medicationId;
}
