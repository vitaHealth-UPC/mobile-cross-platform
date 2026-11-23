import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/presentation/theme/tata_colors.dart';
import '../../application/readmodels/monitored_dose.dart';
import '../../application/readmodels/recorded_alert_event.dart';
import '../../domain/entities/caregiver_alert.dart';
import '../../domain/value_objects/alert_status.dart';
import '../texts/monitoring_texts.dart';

/// Gradient surface shared by the medication hero and follow-up actions.
class AlertDetailSurface extends StatelessWidget {
  const AlertDetailSurface({
    super.key,
    required this.colors,
    required this.child,
  });
  final List<Color> colors;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      gradient: LinearGradient(colors: colors),
      borderRadius: BorderRadius.circular(18),
      boxShadow: const [
        BoxShadow(
          color: Color(0x141A2138),
          blurRadius: 18,
          offset: Offset(0, 6),
        ),
      ],
    ),
    child: child,
  );
}

/// Compact status, separate from the server's follow-up priority.
class AlertDetailStatusPill extends StatelessWidget {
  const AlertDetailStatusPill({super.key, required this.status});
  final AlertStatus status;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: const Color(0xFFF9F0D6),
      borderRadius: BorderRadius.circular(13),
    ),
    child: Text(
      alertStatusLabel(AppLocalizations.of(context), status),
      style: const TextStyle(fontSize: 11, color: Color(0xFF79541C)),
    ),
  );
}

/// Medication evidence comes from the selected alert and its authorized dose read.
class AlertMedicationHero extends StatelessWidget {
  const AlertMedicationHero({super.key, required this.alert, this.dose});
  final CaregiverAlert alert;
  final MonitoredDose? dose;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    return AlertDetailSurface(
      colors: const [Color(0xFFFFF0E8), Color(0xFFFADFD0)],
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: SvgPicture.asset(
              'assets/icons/alerts_warning.svg',
              width: 24,
              height: 24,
              excludeFromSemantics: true,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert.medicationName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: TataColors.ink,
                  ),
                ),
                if (dose != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    dose!.dose,
                    style: const TextStyle(fontSize: 13, color: TataColors.ink),
                  ),
                ],
                const SizedBox(height: 12),
                Text(
                  DateFormat(
                    'd MMM, h:mm a',
                    locale,
                  ).format(alert.scheduledAt.toLocal()),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: TataColors.ink,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // The 2x export includes the shadow beyond Figma's 88 px tablet slot.
          SizedBox.square(
            dimension: 88,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: -18,
                  top: -9,
                  width: 124,
                  height: 124,
                  child: Image.asset(
                    'assets/illustrations/alert_tablet.png',
                    fit: BoxFit.contain,
                    excludeFromSemantics: true,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Renders only recorded events. No reminder number or delivery time is fabricated.
class AlertReminderTimeline extends StatelessWidget {
  const AlertReminderTimeline({super.key, required this.events});
  final List<RecordedAlertEvent> events;

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final ordered = [...events]
      ..sort((a, b) => a.occurredAt.compareTo(b.occurredAt));
    final firstReminderIndex = ordered.indexWhere(
      (event) => event.type == RecordedAlertEventType.reinforcedReminderSent,
    );
    String label(RecordedAlertEventType type) => switch (type) {
      RecordedAlertEventType.intakeScheduled => text.fmEventScheduled,
      RecordedAlertEventType.reinforcedReminderSent => text.fmEventReinforced,
      RecordedAlertEventType.alertGenerated => text.fmEventOpened,
      RecordedAlertEventType.alertClosed => text.fmEventClosed,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          text.fmReminderTimeline,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: TataColors.ink,
          ),
        ),
        const SizedBox(height: 16),
        for (var i = 0; i < ordered.length; i++)
          Builder(
            builder: (context) {
              final event = ordered[i];
              final asset = switch (event.type) {
                RecordedAlertEventType.intakeScheduled => 'alert_scheduled',
                RecordedAlertEventType.reinforcedReminderSent =>
                  i == firstReminderIndex
                      ? 'alert_first_reminder'
                      : 'alert_second_reminder',
                RecordedAlertEventType.alertGenerated => 'alerts_warning',
                RecordedAlertEventType.alertClosed => 'alerts_confirmed',
              };
              return Padding(
                padding: const EdgeInsets.only(left: 16),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        width: 24,
                        child: Column(
                          children: [
                            SvgPicture.asset(
                              'assets/icons/$asset.svg',
                              width: asset.startsWith('alert_') ? 22 : 24,
                              height: asset.startsWith('alert_') ? 22 : 24,
                              excludeFromSemantics: true,
                            ),
                            if (i < ordered.length - 1)
                              Expanded(
                                child: Center(
                                  child: Container(
                                    width: 2,
                                    color: const Color(0xFFDDDDE7),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 20, top: 2),
                          child: Wrap(
                            spacing: 14,
                            runSpacing: 5,
                            children: [
                              Text(
                                DateFormat(
                                  'h:mm a',
                                  locale,
                                ).format(event.occurredAt.toLocal()),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: TataColors.ink,
                                ),
                              ),
                              Text(
                                label(event.type),
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF5B6475),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}
