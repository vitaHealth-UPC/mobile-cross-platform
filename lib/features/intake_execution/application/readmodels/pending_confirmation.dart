/// Durable intent to confirm one intake that has no server receipt yet.
final class PendingConfirmation {
  const PendingConfirmation({required this.intakeId, required this.queuedAt});

  final String intakeId;

  /// UTC instant the adult confirmed; the server still decides the outcome.
  final DateTime queuedAt;
}
