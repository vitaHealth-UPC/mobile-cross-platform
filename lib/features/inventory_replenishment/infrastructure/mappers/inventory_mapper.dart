import '../../domain/entities/inventory.dart';

/// Reads the server's inventory resource; anything malformed throws FormatException.
abstract final class InventoryMapper {
  static Inventory inventory(Object? body) {
    if (body is! Map<String, Object?>) {
      throw const FormatException('Inventory expected');
    }
    final batches = body['batches'];
    if (batches is! List) throw const FormatException('Batches expected');
    try {
      return Inventory(
        id: _text(body, 'id'),
        medicationId: _text(body, 'medicationId'),
        remainingStock: _int(body, 'remainingStock'),
        replenishmentThreshold: _int(body, 'replenishmentThreshold'),
        lowStock: _bool(body, 'lowStock'),
        daysRemaining: _optionalInt(body, 'daysRemaining'),
        batches: [for (final batch in batches) _batch(batch)],
      );
    } on ArgumentError {
      throw const FormatException('Invalid inventory');
    }
  }

  /// Stable error code of a failure body, when the server sent one.
  static String? errorCode(Object? body) =>
      body is Map<String, Object?> && body['code'] is String
      ? body['code']! as String
      : null;

  static InventoryBatch _batch(Object? body) {
    if (body is! Map<String, Object?>) {
      throw const FormatException('Batch expected');
    }
    final lot = body['lot'];
    if (lot != null && lot is! String) throw const FormatException('Lot');
    return InventoryBatch(
      id: _text(body, 'id'),
      quantity: _int(body, 'quantity'),
      registeredAt: _instant(body, 'registeredAt'),
      lot: lot as String?,
    );
  }

  static String _text(Map<String, Object?> body, String key) {
    final value = body[key];
    if (value is! String || value.trim().isEmpty) throw FormatException(key);
    return value;
  }

  static int _int(Map<String, Object?> body, String key) {
    final value = body[key];
    if (value is! int) throw FormatException(key);
    return value;
  }

  static int? _optionalInt(Map<String, Object?> body, String key) {
    final value = body[key];
    if (value != null && value is! int) throw FormatException(key);
    return value as int?;
  }

  static bool _bool(Map<String, Object?> body, String key) {
    final value = body[key];
    if (value is! bool) throw FormatException(key);
    return value;
  }

  static DateTime _instant(Map<String, Object?> body, String key) {
    final value = DateTime.parse(_text(body, key));
    if (!value.isUtc) throw FormatException(key);
    return value;
  }
}
