/// Intent to load or reload the treatments of the selected adult.
sealed class TreatmentListEvent {
  const TreatmentListEvent();
}

final class TreatmentListRequested extends TreatmentListEvent {
  const TreatmentListRequested();
}
