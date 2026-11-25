/// Stock operations the host lends to the medication screens. Inventory is a
/// different bounded context, so Treatment Management only sees these
/// callbacks, never its blocs or repositories.
final class MedicationStockHooks {
  const MedicationStockHooks({
    required this.remaining,
    required this.registerInitial,
  });

  /// Remaining units of a medication, or null when it has no stock yet or it
  /// could not be read.
  final Future<int?> Function(String medicationId) remaining;

  /// Registers the initial stock right after the medication; returns null on
  /// success or a stable error code.
  final Future<String?> Function(
    String medicationId, {
    required String quantity,
    required String threshold,
  })
  registerInitial;
}
