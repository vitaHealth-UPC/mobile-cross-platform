import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/presentation/theme/tata_colors.dart';
import '../../application/readmodels/treatment_readmodels.dart';
import '../../domain/value_objects/treatment_status.dart';

/// Figma 563:142 with real regimens; purpose and future intakes are not inferred from a prescription.
class MedicationDetailsScreen extends StatelessWidget {
  const MedicationDetailsScreen({
    super.key,
    required this.item,
    required this.navigationBar,
    required this.onBack,
    this.next,
    this.scheduleUnknown = false,
    this.onDose,
  });
  final MyMedication item;
  final MedicationNextDose? next;
  final bool scheduleUnknown;
  final ValueChanged<String>? onDose;
  final Widget navigationBar;
  final VoidCallback onBack;
  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    return Scaffold(
      bottomNavigationBar: navigationBar,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(14, 28, 22, 24),
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: onBack,
                  tooltip: text.back,
                  icon: const Icon(Icons.chevron_left),
                ),
                Expanded(
                  child: Text(
                    text.catalogDetailTitle,
                    style: const TextStyle(
                      fontFamily: 'DMSerifDisplay',
                      fontSize: 21,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  colors: [Color(0xFFEEE8FF), Color(0xFFE5DDF8)],
                ),
              ),
              child: Row(
                children: [
                  Image.asset(
                    'assets/illustrations/home_tablet.png',
                    width: 82,
                    height: 96,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: TataColors.ink,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          item.treatments
                                  .where(
                                    (treatment) =>
                                        treatment.status ==
                                        TreatmentStatus.active,
                                  )
                                  .firstOrNull
                                  ?.dose ??
                              item.presentation,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 8,
                ),
                title: Text(
                  text.homeNextDose,
                  style: const TextStyle(fontSize: 13, color: TataColors.muted),
                ),
                subtitle: Text(
                  next == null
                      ? (scheduleUnknown
                            ? text.catalogScheduleUnavailable
                            : text.catalogNoNext)
                      : DateFormat(
                          'h:mm a',
                          Localizations.localeOf(context).toLanguageTag(),
                        ).format(next!.scheduledAt.toLocal()),
                  style: TextStyle(
                    fontSize: next == null ? 14 : 24,
                    fontWeight: FontWeight.w700,
                    color: TataColors.ink,
                  ),
                ),
                trailing: next == null
                    ? null
                    : const Icon(
                        Icons.chevron_right,
                        color: TataColors.primary,
                      ),
                onTap: next == null || onDose == null
                    ? null
                    : () => onDose!(next!.intakeId),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              text.doseInformation,
              style: const TextStyle(fontSize: 13, color: TataColors.muted),
            ),
            const SizedBox(height: 8),
            if (item.treatments.isEmpty) Text(text.catalogNoRegimen),
            for (final treatment in item.treatments) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      treatment.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      switch (treatment.status) {
                        TreatmentStatus.active => text.catalogTreatmentActive,
                        TreatmentStatus.paused => text.catalogTreatmentPaused,
                        TreatmentStatus.draft => text.catalogTreatmentDraft,
                      },
                      style: const TextStyle(
                        fontSize: 13,
                        color: TataColors.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (treatment.dose case final dose?)
                      _Row(
                        icon: Icons.medication_outlined,
                        label: text.doseDoseLabel,
                        value: dose,
                      ),
                    _Row(
                      icon: Icons.schedule,
                      label: text.doseWhenLabel,
                      value: [
                        treatment.scheduledTimes
                            .map(
                              (time) => time.endsWith(':00') && time.length == 8
                                  ? time.substring(0, 5)
                                  : time,
                            )
                            .join(', '),
                        if (treatment.recurrenceZone != null)
                          treatment.recurrenceZone!,
                      ].join(' · '),
                    ),
                    if (treatment.instructions.trim().isNotEmpty)
                      _Row(
                        icon: Icons.description_outlined,
                        label: text.doseInstructionsLabel,
                        value: treatment.instructions,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFEEE8FF),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          text.doseBeforeTitle,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          text.dosePrepareMedication,
                          style: const TextStyle(
                            fontSize: 13,
                            color: TataColors.muted,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          text.dosePrepareWater,
                          style: const TextStyle(
                            fontSize: 13,
                            color: TataColors.muted,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          text.dosePrepareSeat,
                          style: const TextStyle(
                            fontSize: 13,
                            color: TataColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ExcludeSemantics(
                    child: Image.asset(
                      'assets/illustrations/dose_water_plant.png',
                      width: 88,
                      height: 100,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) {
    final large = MediaQuery.textScalerOf(context).scale(14) > 18;
    final caption = Text(
      label,
      style: const TextStyle(fontSize: 13, color: TataColors.muted),
    );
    final content = Text(
      value,
      style: const TextStyle(fontSize: 13, color: TataColors.ink),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF716BD0)),
          const SizedBox(width: 10),
          if (large)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [caption, const SizedBox(height: 4), content],
              ),
            )
          else ...[
            Expanded(flex: 2, child: caption),
            const SizedBox(width: 8),
            Expanded(flex: 3, child: content),
          ],
        ],
      ),
    );
  }
}
