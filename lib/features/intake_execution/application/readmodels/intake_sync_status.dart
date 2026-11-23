/// What the adult should know about the device's connection to the server.
final class IntakeSyncStatus {
  const IntakeSyncStatus({
    this.queued = 0,
    this.offline = false,
    this.resolved = 0,
  });

  /// Confirmations of the current adult still waiting for a server receipt.
  final int queued;

  /// The last server request failed, so stored data may be out of date.
  final bool offline;

  /// Running count of queued confirmations the server has answered.
  final int resolved;

  @override
  bool operator ==(Object other) =>
      other is IntakeSyncStatus &&
      queued == other.queued &&
      offline == other.offline &&
      resolved == other.resolved;

  @override
  int get hashCode => Object.hash(queued, offline, resolved);
}
