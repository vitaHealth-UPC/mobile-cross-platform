/// Account or challenge action whose diagnostic output excludes personal data.
sealed class RegistrationEvent {
  const RegistrationEvent();
  @override
  String toString() => 'RegistrationEvent[REDACTED]';
}

/// Transient name, email and password used to request a pending caregiver account.
final class RegistrationSubmitted extends RegistrationEvent {
  const RegistrationSubmitted(this.name, this.email, this.password);
  final String name;
  final String email;
  final String password;
}

/// Transient six-digit challenge entered by the user for the pending account.
final class VerificationSubmitted extends RegistrationEvent {
  const VerificationSubmitted(this.code);
  final String code;
}

/// Renews the challenge for the pending account already held by the flow.
final class VerificationRequested extends RegistrationEvent {
  const VerificationRequested();
}
