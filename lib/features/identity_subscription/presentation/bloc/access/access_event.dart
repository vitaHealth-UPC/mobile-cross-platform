/// User or startup intent handled by the access state machine.
sealed class AccessEvent {
  const AccessEvent();
}

/// Requests validation of a stored session against the current server identity.
final class AccessRestoreRequested extends AccessEvent {
  const AccessRestoreRequested();
}

/// Transient password sign-in input; diagnostic output redacts both fields.
final class AccessSignInSubmitted extends AccessEvent {
  const AccessSignInSubmitted(this.email, this.password);
  final String email;
  final String password;

  @override
  String toString() => 'AccessSignInSubmitted[REDACTED]';
}

/// Requests local invalidation and revocation of the captured server credential.
final class AccessSignOutRequested extends AccessEvent {
  const AccessSignOutRequested();
}
