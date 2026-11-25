import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/presentation/theme/tata_colors.dart';
import '../bloc/treatment_setup/treatment_setup_state.dart';
import 'prescription_fields.dart';
import 'treatment_visuals.dart';

/// Review of validated regimen values, one block per medication; a visual
/// preview never fabricates intake evidence.
class TreatmentSetupReview extends StatelessWidget {
  const TreatmentSetupReview({super.key, required this.state});
  final TreatmentSetupState state;

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          text.tmTreatmentName,
          style: const TextStyle(fontSize: 11, color: TataColors.muted),
        ),
        const SizedBox(height: 8),
        TreatmentSurface(
          child: Text(
            state.treatmentName,
            style: const TextStyle(fontSize: 14),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          text.tmMedicationCount(state.medications.length),
          style: const TextStyle(fontSize: 11, color: TataColors.muted),
        ),
        const SizedBox(height: 8),
        for (final medication in state.medications) ...[
          _RegimenSummary(
            label: medication.label,
            regimen: state.regimens[medication.id] ?? const SetupRegimen(),
          ),
          const SizedBox(height: 12),
        ],
        const SizedBox(height: 4),
        TreatmentSurface(
          color: const Color(0xFFF1ECFF),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                text.tmStepReminders,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                state.followUpDelayMinutes == null
                    ? text.tmDefaultFollowUp
                    : text.tmFollowUpSummary(state.followUpDelayMinutes!),
                style: const TextStyle(fontSize: 12, color: TataColors.muted),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RegimenSummary extends StatelessWidget {
  const _RegimenSummary({required this.label, required this.regimen});
  final String label;
  final SetupRegimen regimen;

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    final values = [
      (text.tmDoseShort, regimen.dose),
      (text.tmFrequencyShort, frequencyLabel(text, regimen.frequency)),
      (text.tmTimesShort, regimen.scheduledTimes.join(', ')),
      if (regimen.instructions.isNotEmpty)
        (text.tmInstructionsShort, regimen.instructions),
    ];
    return TreatmentSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: TataColors.ink,
                  ),
                ),
              ),
              ExcludeSemantics(
                child: SvgPicture.asset(
                  'assets/icons/treatment_medication.svg',
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final large = MediaQuery.textScalerOf(context).scale(14) > 18;
              final width = large
                  ? constraints.maxWidth
                  : (constraints.maxWidth - 16) / 2;
              return Wrap(
                spacing: 16,
                runSpacing: 20,
                children: [
                  for (final value in values)
                    SizedBox(
                      width: width,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            value.$1,
                            style: const TextStyle(
                              fontSize: 11,
                              color: TataColors.muted,
                            ),
                          ),
                          const SizedBox(height: 7),
                          Text(
                            value.$2,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: TataColors.ink,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Proposed local times only: no progress bars, taken doses or calendar IDs are invented.
class TreatmentSchedulePreview extends StatelessWidget {
  const TreatmentSchedulePreview({super.key, required this.times});
  final List<String> times;
  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    return TreatmentSurface(
      color: const Color(0xFFE8F2FA),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            text.tmSchedulePreview,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              for (final time in times)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    time,
                    style: const TextStyle(
                      fontSize: 12,
                      color: TataColors.primary,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
