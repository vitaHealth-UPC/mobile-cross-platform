/// Device-local display identity for the PIN shortcut.
/// It grants no access: the server still validates the PIN and the care link.
final class RememberedAdult {
  RememberedAdult({required this.id, this.name}) {
    if (id.trim().isEmpty || id != id.trim()) {
      throw ArgumentError('Invalid older adult identifier');
    }
  }

  final String id;

  /// Optional because the profile read can fail without blocking PIN setup.
  final String? name;

  @override
  String toString() => 'RememberedAdult[personalData=REDACTED]';
}
