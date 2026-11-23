/// Ways the caregiver can reach the older adult after an alert.
enum ContactChannelType {
  phone('PHONE'),
  whatsapp('WHATSAPP');

  const ContactChannelType(this.wireName);
  final String wireName;

  static ContactChannelType? fromWire(Object? value) {
    for (final type in values) {
      if (type.wireName == value) return type;
    }
    return null;
  }
}

/// Channel the caregiver can use to reach the older adult after an alert.
final class ContactChannel {
  ContactChannel({required this.type, required this.value}) {
    if (value.trim().isEmpty) {
      throw ArgumentError('A contact value is required');
    }
  }

  final ContactChannelType type;
  final String value;

  /// Digits only, with the country code when the value carries it, as wa.me links need.
  String get digits => value.replaceAll(RegExp(r'\D'), '');
}
