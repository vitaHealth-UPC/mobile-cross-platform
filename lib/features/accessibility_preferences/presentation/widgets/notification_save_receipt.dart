import 'package:flutter/material.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../bloc/notifications/notification_preferences_state.dart';

/// Figma 563:5090 receipt for the operation actually acknowledged by the server.
class NotificationSaveReceipt extends StatelessWidget {
  const NotificationSaveReceipt({super.key, required this.receipt});
  final NotificationPreferenceReceipt receipt;

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    final detail = switch (receipt) {
      NotificationPreferenceReceipt.policy => text.pfPolicyReceipt,
      NotificationPreferenceReceipt.channels => text.pfChannelsReceipt,
      NotificationPreferenceReceipt.quietHours => text.pfQuietReceipt,
    };
    return Semantics(
      liveRegion: true,
      child: Container(
        key: const Key('notification-save-receipt'),
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(22, 4, 22, 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5EB),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text.pfPreferencesSaved,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2E6E45),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              detail,
              style: const TextStyle(fontSize: 9.5, color: Color(0xFF637087)),
            ),
          ],
        ),
      ),
    );
  }
}
