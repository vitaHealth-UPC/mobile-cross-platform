/// Transient recovery intent with redacted diagnostic output.
sealed class RecoveryEvent {
  const RecoveryEvent();
  @override
  String toString() => 'RecoveryEvent[REDACTED]';
}

/// Requests a recovery code without disclosing whether the email owns an account.
final class RecoveryRequested extends RecoveryEvent {
  const RecoveryRequested(this.email);
  final String email;
}

/// Submits the current code and new password without requesting automatic login.
final class RecoveryCompleted extends RecoveryEvent {
  const RecoveryCompleted(this.code, this.newPassword);
  final String code;
  final String newPassword;
}
