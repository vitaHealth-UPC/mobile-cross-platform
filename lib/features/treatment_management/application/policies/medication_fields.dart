/// Input bound shared by RegisterMedicationRequest and UpdateMedicationRequest.
const maxMedicationFieldLength = 160;

/// Applies the same trimmed field bounds to medication creation and editing.
bool medicationFieldsTooLong(String name, String presentation) =>
    name.trim().length > maxMedicationFieldLength ||
    presentation.trim().length > maxMedicationFieldLength;
