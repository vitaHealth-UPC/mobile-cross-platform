import '../../domain/value_objects/contact_channel.dart';

/// Opens the phone or messaging app for a contact channel. Returns false when the device
/// has no app able to handle it.
abstract interface class ContactLauncher {
  Future<bool> open(ContactChannel channel);
}
