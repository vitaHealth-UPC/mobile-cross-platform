import 'package:flutter/material.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/presentation/theme/tata_colors.dart';
import '../../domain/value_objects/treatment_status.dart';
import '../bloc/treatment_management/treatment_management_state.dart';
import '../texts/treatment_texts.dart';

/// Read-only regimen evidence with native edit and lifecycle actions when authorized.
class TreatmentManagementCard extends StatelessWidget {
  const TreatmentManagementCard({
    super.key,
    required this.state,
    required this.onEdit,
    required this.onPause,
    required this.onResume,
  });
  final TreatmentManagementState state;
  final VoidCallback onEdit;
  final VoidCallback onPause;
  final VoidCallback onResume;
  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    final detail = state.detail!;
    final actionStyle = OutlinedButton.styleFrom(
      backgroundColor: const Color(0xFFF1ECFF),
      foregroundColor: TataColors.primary,
      side: const BorderSide(color: Color(0xFFC2B5E5)),
      shape: const StadiumBorder(),
      minimumSize: const Size(0, 44),
      textStyle: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
    );
    final actions = [
      OutlinedButton(
        style: actionStyle,
        onPressed: state.busy ? null : onEdit,
        child: Text(text.tmEditRegimen),
      ),
      OutlinedButton(
        style: actionStyle,
        onPressed: state.busy
            ? null
            : detail.status == TreatmentStatus.active
            ? onPause
            : onResume,
        child: Text(
          detail.status == TreatmentStatus.active
              ? text.tmPause
              : text.tmResume,
        ),
      ),
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE8EAF1)),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x141A2138),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: 16,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                detail.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: TataColors.ink,
                ),
              ),
              Text(
                treatmentStatusText(text, detail.status),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: detail.status == TreatmentStatus.active
                      ? const Color(0xFF2E734D)
                      : const Color(0xFF9D702B),
                ),
              ),
            ],
          ),
          if (state.medication != null) ...[
            const SizedBox(height: 16),
            Text(
              state.medication!.label,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ],
          if (detail.configured) ...[
            const SizedBox(height: 12),
            Text(
              [
                detail.dose!,
                detail.frequency!,
                detail.scheduledTimes.join(', '),
              ].join(', '),
              style: const TextStyle(fontSize: 12, color: TataColors.muted),
            ),
            const SizedBox(height: 12),
            Text(
              [
                if (detail.instructions.trim().isNotEmpty) detail.instructions,
                detail.followUpDelayMinutes == null
                    ? text.tmDefaultFollowUp
                    : text.tmFollowUpCompact(detail.followUpDelayMinutes!),
              ].join(', '),
              style: const TextStyle(fontSize: 12, color: TataColors.muted),
            ),
            if (detail.recurrenceZone != null) ...[
              const SizedBox(height: 8),
              Text(
                detail.recurrenceZone!,
                style: const TextStyle(fontSize: 11, color: TataColors.muted),
              ),
            ],
          ],
          if (!state.manageable) ...[
            const SizedBox(height: 12),
            Text(
              text.tmDraftIncomplete,
              style: const TextStyle(fontSize: 12, color: TataColors.muted),
            ),
          ],
          if (state.medicationInactive) ...[
            const SizedBox(height: 12),
            Text(
              text.tmMedicationInactiveNotice,
              style: const TextStyle(fontSize: 12, color: TataColors.muted),
            ),
          ],
          if (state.manageable && !state.medicationInactive) ...[
            const SizedBox(height: 20),
            if (MediaQuery.textScalerOf(context).scale(14) > 18) ...[
              for (final action in actions) ...[
                SizedBox(width: double.infinity, child: action),
                const SizedBox(height: 8),
              ],
            ] else
              Row(
                children: [
                  Expanded(child: actions.first),
                  const SizedBox(width: 16),
                  Expanded(child: actions.last),
                ],
              ),
          ],
        ],
      ),
    );
  }
}
