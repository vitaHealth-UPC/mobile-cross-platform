import '../../../application/readmodels/treatment_detail.dart';

enum TreatmentListStatus { loading, ready, failure }

/// Treatments of one adult; the last successful list survives a failed refresh.
final class TreatmentListState {
  const TreatmentListState({
    this.status = TreatmentListStatus.loading,
    this.treatments = const [],
    this.errorCode,
    this.activated = false,
    this.medicationLabels = const {},
  });

  final TreatmentListStatus status;
  final List<TreatmentDetail> treatments;
  final String? errorCode;
  final bool activated;

  /// "Name presentation" by medication id, to label each regimen.
  final Map<String, String> medicationLabels;

  /// Treatments grouped by plan, in the order their first regimen appears:
  /// one treatment may hold several medications.
  List<List<TreatmentDetail>> get plans {
    final groups = <String, List<TreatmentDetail>>{};
    for (final treatment in treatments) {
      groups.putIfAbsent(treatment.planId, () => []).add(treatment);
    }
    return [for (final group in groups.values) List.unmodifiable(group)];
  }
}
