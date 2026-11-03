/// Caregiver setup intents; diagnostic output excludes personal data.
sealed class ProfilesEvent {
  const ProfilesEvent();
  @override
  String toString() => 'ProfilesEvent[REDACTED]';
}

/// Refreshes the authorized list without inventing pending relationships.
final class ProfilesRequested extends ProfilesEvent {
  const ProfilesRequested();
}

/// Transient profile input supplied by the caregiver's native form.
final class OlderAdultSubmitted extends ProfilesEvent {
  const OlderAdultSubmitted(this.name, this.birthDate);
  final String name;
  final DateTime birthDate;
}

/// Requests evidence only for the profile acknowledged in this setup flow.
final class LinkingCodeRequested extends ProfilesEvent {
  const LinkingCodeRequested();
}
