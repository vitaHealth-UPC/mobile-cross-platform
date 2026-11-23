import '../../domain/entities/inventory.dart';

/// Observable phases of the inventory screen (Figma 563:1632, 563:5213, 563:5284).
enum InventoryPhase {
  loading,

  /// The stock could not be read; [InventoryState.errorCode] says why.
  failure,

  /// The medication has no stock yet, so only the initial form is offered.
  notInitialized,
  ready,
}

/// Field that rejected the typed value; the screen marks it in place.
enum InventoryField { quantity, threshold, lot }

final class InventoryState {
  const InventoryState({
    this.phase = InventoryPhase.loading,
    this.inventory,
    this.submitting = false,
    this.invalidField,
    this.errorCode,
    this.replenished = false,
  });

  final InventoryPhase phase;
  final Inventory? inventory;

  /// A write is in flight; the form is locked so it is sent only once.
  final bool submitting;
  final InventoryField? invalidField;

  /// Failure to read, or a write the server refused, as a stable code.
  final String? errorCode;

  /// The last write was a replenishment the server acknowledged.
  final bool replenished;

  InventoryState copyWith({
    InventoryPhase? phase,
    Inventory? inventory,
    bool? submitting,
    InventoryField? invalidField,
    String? errorCode,
    bool? replenished,
  }) => InventoryState(
    phase: phase ?? this.phase,
    inventory: inventory ?? this.inventory,
    submitting: submitting ?? this.submitting,
    invalidField: invalidField,
    errorCode: errorCode,
    replenished: replenished ?? false,
  );
}
