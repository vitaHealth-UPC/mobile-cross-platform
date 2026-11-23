import '../../domain/value_objects/contact_channel.dart';

/// What the alert detail and the family summary need to offer contact: [channel] is null
/// when none exists.
final class ContactOption {
  const ContactOption({required this.channel, required this.firstName});
  final ContactChannel? channel;
  final String? firstName;
}
