import 'package:flutter/material.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/presentation/theme/tata_colors.dart';
import '../bloc/treatment_setup/treatment_setup_state.dart';

/// Review of validated regimen values; a visual preview never fabricates intake evidence.
class TreatmentSetupReview extends StatelessWidget {
  const TreatmentSetupReview({
    super.key,
    required this.state,
    required this.medication,
  });
  final TreatmentSetupState state;
  final Widget medication;
  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    final values = [
      (text.tmDoseShort, state.dose),
      (text.tmFrequencyShort, state.frequency),
      (text.tmTimesShort, state.scheduledTimes.join(', ')),
      if (state.instructions.isNotEmpty)
        (text.tmInstructionsShort, state.instructions),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          text.tmTreatmentName,
          style: const TextStyle(fontSize: 11, color: TataColors.muted),
        ),
        const SizedBox(height: 8),
        _Card(
          child: Text(
            state.treatmentName,
            style: const TextStyle(fontSize: 14),
          ),
        ),
        const SizedBox(height: 16),
        medication,
        const SizedBox(height: 16),
        _Card(
          child: LayoutBuilder(
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
        ),
        const SizedBox(height: 16),
        _Card(
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

/// Proposed local times only: no progress bars, taken doses or calendar IDs are invented.
class TreatmentSchedulePreview extends StatelessWidget {
  const TreatmentSchedulePreview({super.key, required this.times});
  final List<String> times;
  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    return _Card(
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

class _Card extends StatelessWidget {
  const _Card({required this.child, this.color = Colors.white});
  final Widget child;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: color,
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
