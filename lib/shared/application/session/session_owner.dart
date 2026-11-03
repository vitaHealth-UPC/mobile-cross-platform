/// Actor scope recognized by Tata sessions, independent of presentation labels.
enum SessionRole { caregiver, olderAdult, linkSetup }

/// Validated actor identifier and role used to partition authenticated data.
final class SessionOwner {
  SessionOwner(this.id, this.role, {this.careLinkId}) {
    if (id.trim().isEmpty || id != id.trim()) {
      throw ArgumentError('Invalid session owner');
    }
    if (role != SessionRole.caregiver &&
        (careLinkId == null ||
            careLinkId!.isEmpty ||
            careLinkId != careLinkId!.trim())) {
      throw ArgumentError(
        'Adult and setup sessions require a relationship scope',
      );
    }
    if (role == SessionRole.caregiver && careLinkId != null) {
      throw ArgumentError(
        'Caregiver sessions do not carry an adult relationship scope',
      );
    }
  }

  final String id;
  final SessionRole role;

  /// Relationship boundary required for both restricted and full adult access.
  final String? careLinkId;

  @override
  bool operator ==(Object other) =>
      other is SessionOwner &&
      id == other.id &&
      role == other.role &&
      careLinkId == other.careLinkId;

  @override
  int get hashCode => Object.hash(id, role, careLinkId);
}
