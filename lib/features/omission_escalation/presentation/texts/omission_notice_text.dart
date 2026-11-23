import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/value_objects/omission_push.dart';

/// Title and body of a local notice, in the user's language. The backend writes its own
/// text in English, so the device builds the notice from the kind and the medication.
final class OmissionNoticeText {
  const OmissionNoticeText({required this.title, required this.body});
  final String title;
  final String body;

  factory OmissionNoticeText.of(AppLocalizations text, OmissionPush push) {
    final medication = push.medicationName?.trim();
    final named = medication != null && medication.isNotEmpty;
    return switch (push.kind) {
      OmissionPushKind.reinforcedReminder => OmissionNoticeText(
        title: text.oeReminderTitle,
        body: named
            ? text.oeReminderTextNamed(medication)
            : text.oeReminderText,
      ),
      OmissionPushKind.caregiverAlert => OmissionNoticeText(
        title: text.oeAlertTitle,
        body: named ? text.oeAlertTextNamed(medication) : text.oeAlertText,
      ),
    };
  }
}
