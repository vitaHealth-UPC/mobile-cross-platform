/// Account flow phases distinguishing pending verification from issued access.
enum RegistrationStatus {
  editing,
  submitting,
  pending,
  verifying,
  resending,
  verified,
}

/// Passwords and verification codes never enter persistent presentation state.
final class RegistrationState {
  const RegistrationState({
    this.status = RegistrationStatus.editing,
    this.accountId,
    this.email,
    this.errorCode,
    this.resent = false,
  });
  final RegistrationStatus status;
  final String? accountId;
  final String? email;
  final String? errorCode;
  final bool resent;

  bool get busy =>
      status == RegistrationStatus.submitting ||
      status == RegistrationStatus.verifying ||
      status == RegistrationStatus.resending;
  bool get hasAccount => accountId != null;
}
