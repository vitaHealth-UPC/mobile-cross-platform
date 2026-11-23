/// Recovery phases separating accepted code requests from password replacement.
enum RecoveryStatus {
  editing,
  requesting,
  codeRequested,
  completing,
  completed,
}

/// Public recovery progress, recipient and safe error code without password or code.
final class RecoveryState {
  const RecoveryState({
    this.status = RecoveryStatus.editing,
    this.email,
    this.errorCode,
  });
  final RecoveryStatus status;
  final String? email;
  final String? errorCode;
  bool get busy =>
      status == RecoveryStatus.requesting ||
      status == RecoveryStatus.completing;
}
