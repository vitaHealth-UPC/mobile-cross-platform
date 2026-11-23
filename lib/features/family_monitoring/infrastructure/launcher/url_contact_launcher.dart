import 'package:url_launcher/url_launcher.dart';

import '../../application/ports/contact_launcher.dart';
import '../../domain/value_objects/contact_channel.dart';

/// [ContactLauncher] backed by `tel:` and `https://wa.me/` links.
final class UrlContactLauncher implements ContactLauncher {
  const UrlContactLauncher();

  @override
  Future<bool> open(ContactChannel channel) async {
    final digits = channel.digits;
    if (digits.isEmpty) return false;
    final uri = switch (channel.type) {
      ContactChannelType.phone => Uri(scheme: 'tel', path: '+$digits'),
      ContactChannelType.whatsapp => Uri.https('wa.me', '/$digits'),
    };
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } on Object {
      return false;
    }
  }
}
