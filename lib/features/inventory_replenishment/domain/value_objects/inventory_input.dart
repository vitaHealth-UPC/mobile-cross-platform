/// Validation of what the caregiver types, before anything reaches the server.
///
/// The server repeats every rule; these checks only avoid a request that is
/// certain to be rejected and keep the error next to the field (Figma 563:5213).
abstract final class InventoryInput {
  /// Largest lot or note the server accepts.
  static const maxLotLength = 200;

  /// Units received or initially available: a whole number greater than zero.
  static int? quantity(String raw) {
    final value = int.tryParse(raw.trim());
    return value != null && value > 0 ? value : null;
  }

  /// Low-stock threshold: a whole number that is zero or more.
  static int? threshold(String raw) {
    final value = int.tryParse(raw.trim());
    return value != null && value >= 0 ? value : null;
  }

  /// Trimmed lot; blank means "no lot". Returns false when it is too long.
  static ({bool valid, String? value}) lot(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return (valid: true, value: null);
    return value.length <= maxLotLength
        ? (valid: true, value: value)
        : (valid: false, value: null);
  }
}
