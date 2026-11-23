import 'package:flutter/material.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../bloc/treatment_management/treatment_management_state.dart';

/// Receipts for the actual operations in Figma 563:2455 and 563:2537.
class TreatmentManagementReceipt extends StatelessWidget {
  const TreatmentManagementReceipt({super.key, required this.notice});
  final TreatmentManagementNotice notice;

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    final inactive = notice == TreatmentManagementNotice.medicationDeactivated;
    final (title, body) = switch (notice) {
      TreatmentManagementNotice.regimenSaved => (
        text.tmChangesSaved,
        text.tmFutureRegimenReceipt,
      ),
      TreatmentManagementNotice.medicationDeactivated => (
        text.tmMedicationDeactivated,
        text.tmDeactivationReceipt,
      ),
      TreatmentManagementNotice.medicationReactivated => (
        text.tmMedicationReactivated,
        text.tmReactivationReceipt,
      ),
    };
    return Semantics(
      liveRegion: true,
      child: Container(
        key: const Key('treatment-management-receipt'),
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(22, 4, 22, 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: inactive ? const Color(0xFFFFF5DB) : const Color(0xFFE8F5EB),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: inactive
                    ? const Color(0xFF575E6E)
                    : const Color(0xFF2E6E45),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              body,
              style: const TextStyle(fontSize: 10, color: Color(0xFF637087)),
            ),
          ],
        ),
      ),
    );
  }
}
