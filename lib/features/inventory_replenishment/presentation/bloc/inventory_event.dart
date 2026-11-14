/// Intent handled by the inventory screen of one medication.
sealed class InventoryEvent {
  const InventoryEvent();
}

/// Loads or retries the stock.
final class InventoryRequested extends InventoryEvent {
  const InventoryRequested();
}

/// Registers the first stock with the typed quantity and threshold (US-40).
final class InitialStockSubmitted extends InventoryEvent {
  const InitialStockSubmitted({
    required this.quantity,
    required this.threshold,
  });
  final String quantity;
  final String threshold;
}

/// Registers received units with an optional lot or note (US-43).
final class ReplenishmentSubmitted extends InventoryEvent {
  const ReplenishmentSubmitted({required this.quantity, this.lot = ''});
  final String quantity;
  final String lot;
}

/// The caregiver edited a field, so earlier feedback no longer applies.
final class InventoryInputChanged extends InventoryEvent {
  const InventoryInputChanged();
}
