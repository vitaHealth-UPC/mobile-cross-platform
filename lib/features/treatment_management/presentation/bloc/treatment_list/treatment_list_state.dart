import '../../../application/readmodels/treatment_readmodels.dart';

enum TreatmentListStatus { loading, ready, failure }

/// Treatments of one adult; the last successful list survives a failed refresh.
final class TreatmentListState {
  const TreatmentListState({
    this.status = TreatmentListStatus.loading,
    this.treatments = const [],
    this.errorCode,
  });

  final TreatmentListStatus status;
  final List<TreatmentDetail> treatments;
  final String? errorCode;
}
