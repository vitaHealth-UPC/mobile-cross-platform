/// One receipt of units: the initial stock (US-40) or a later replenishment (US-43).
final class InventoryBatch {
  InventoryBatch({
    required this.id,
    required this.quantity,
    required this.registeredAt,
    this.lot,
  }) {
    if (id.trim().isEmpty || quantity <= 0) {
      throw ArgumentError('Invalid inventory batch');
    }
    if (lot case final value? when value.trim().isEmpty || value.length > 200) {
      throw ArgumentError('Invalid inventory lot');
    }
  }

  final String id;
  final int quantity;
  final DateTime registeredAt;

  /// Optional lot or note; never invented when the receipt has none.
  final String? lot;
}

/// Stock of one medication as the server last reported it (US-41, US-42).
///
/// The server decides [lowStock] and [daysRemaining]; the app only shows them.
final class Inventory {
  Inventory({
    required this.id,
    required this.medicationId,
    required this.remainingStock,
    required this.replenishmentThreshold,
    required this.lowStock,
    required List<InventoryBatch> batches,
    this.daysRemaining,
  }) : batches = List.unmodifiable(batches) {
    if (id.trim().isEmpty ||
        medicationId.trim().isEmpty ||
        remainingStock < 0 ||
        replenishmentThreshold < 0 ||
        batches.isEmpty ||
        (daysRemaining ?? 0) < 0) {
      throw ArgumentError('Invalid inventory');
    }
  }

  final String id;
  final String medicationId;
  final int remainingStock;
  final int replenishmentThreshold;
  final bool lowStock;

  /// Receipts in the order the server returned them; the first is the initial stock.
  final List<InventoryBatch> batches;

  /// Whole days of coverage, or null when the schedule gives no reliable rate.
  final int? daysRemaining;

  /// The newest receipt after the initial stock. The API does not mark a batch
  /// as initial, so a single batch is never shown as a replenishment.
  InventoryBatch? get lastReplenishment {
    if (batches.length < 2) return null;
    return batches.reduce(
      (latest, batch) =>
          batch.registeredAt.isAfter(latest.registeredAt) ? batch : latest,
    );
  }

  @override
  String toString() => 'Inventory[clinicalData=REDACTED]';
}
