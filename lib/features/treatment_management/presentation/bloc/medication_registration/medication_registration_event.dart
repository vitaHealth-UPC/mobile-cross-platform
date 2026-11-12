/// Intent to register the medication typed by the caregiver.
sealed class MedicationRegistrationEvent {
  const MedicationRegistrationEvent();
}

final class MedicationSubmitted extends MedicationRegistrationEvent {
  const MedicationSubmitted(this.name, this.presentation);
  final String name;
  final String presentation;
}
