/// Medication identity, owner and current availability for treatment configuration.
final class Medication {
  Medication({
    required this.id,
    required this.olderAdultId,
    required this.name,
    required this.presentation,
    required this.active,
  }) {
    if (id.trim().isEmpty ||
        olderAdultId.trim().isEmpty ||
        name.trim().isEmpty ||
        presentation.trim().isEmpty) {
      throw ArgumentError('Invalid medication');
    }
  }

  final String id;
  final String olderAdultId;
  final String name;
  final String presentation;
  final bool active;

  /// Name and presentation as one label, for example `Losartán · 50 mg`.
  String get label => '$name · $presentation';

  @override
  String toString() => 'Medication[clinicalData=REDACTED]';
}
