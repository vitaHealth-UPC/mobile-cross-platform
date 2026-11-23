/// Lifecycle states supported by treatment creation and administration.
enum TreatmentStatus {
  draft,
  active,
  paused;

  /// Recognizes the server vocabulary; unknown values are not guessed.
  static TreatmentStatus? fromWire(Object? value) => switch (value) {
    'DRAFT' => draft,
    'ACTIVE' => active,
    'PAUSED' => paused,
    _ => null,
  };
}
