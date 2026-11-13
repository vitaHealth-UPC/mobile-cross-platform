import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/presentation/theme/tata_colors.dart';
import '../../../../shared/presentation/widgets/async_states.dart';
import '../../application/readmodels/treatment_readmodels.dart';
import '../../domain/value_objects/treatment_status.dart';
import '../bloc/treatment_management/treatment_management_bloc.dart';
import '../bloc/treatment_management/treatment_management_event.dart';
import '../bloc/treatment_management/treatment_management_state.dart';
import '../texts/treatment_texts.dart';
import '../widgets/managed_person_card.dart';
import '../widgets/regimen_editor.dart';
import '../widgets/treatment_management_card.dart';

/// Shows one treatment and offers pause, resume, regimen editing and medication
/// availability. A draft or inactive-medication treatment is shown read-only.
class TreatmentDetailScreen extends StatelessWidget {
  const TreatmentDetailScreen({
    super.key,
    required this.onSessionInvalidated,
    this.personName,
    this.onReturnToPerson,
    this.personAdherenceBadge,
    this.adherence,
    this.navigationBar,
  });

  final VoidCallback onSessionInvalidated;
  final String? personName;
  final VoidCallback? onReturnToPerson;
  final Widget? personAdherenceBadge;

  /// Host-composed treatment-scoped analytics, without a cross-context import.
  final Widget? adherence;
  final Widget? navigationBar;

  Future<void> _editRegimen(
    BuildContext context,
    TreatmentDetail detail,
  ) async {
    final bloc = context.read<TreatmentManagementBloc>();
    final event = await showDialog<RegimenEdited>(
      context: context,
      builder: (_) => RegimenEditor(detail: detail),
    );
    if (event != null && context.mounted) bloc.add(event);
  }

  Future<void> _deactivateMedication(BuildContext context) async {
    final bloc = context.read<TreatmentManagementBloc>();
    final text = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(text.tmDeactivateTitle),
        content: Text(text.tmDeactivateBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(text.tmCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(text.tmDeactivate),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      bloc.add(const TreatmentMedicationDeactivated());
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    return BlocConsumer<TreatmentManagementBloc, TreatmentManagementState>(
      listener: (context, state) {
        if (isSessionFailure(state.errorCode)) {
          onSessionInvalidated();
        } else if (state.regimenSaved) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(text.tmRegimenSaved)));
        }
      },
      builder: (context, state) {
        final bloc = context.read<TreatmentManagementBloc>();
        final name = personName?.trim();
        final knownName = name != null && name.isNotEmpty;
        return Scaffold(
          bottomNavigationBar: navigationBar,
          body: SafeArea(
            bottom: navigationBar == null,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(22, 28, 22, 24),
              children: [
                Row(
                  children: [
                    IconButton(
                      tooltip: text.back,
                      onPressed: state.busy
                          ? null
                          : () => Navigator.of(context).maybePop(),
                      icon: const Icon(
                        Icons.chevron_left,
                        color: TataColors.primary,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        knownName &&
                                state.status !=
                                    TreatmentManagementStatus.failure
                            ? text.tmTreatmentFor(
                                name.split(RegExp(r'\s+')).first,
                              )
                            : text.tmDetailTitle,
                        style: const TextStyle(
                          fontFamily: 'DMSerifDisplay',
                          fontSize: 29,
                          color: TataColors.ink,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  text.tmManagementSubtitle,
                  style: const TextStyle(fontSize: 12, color: TataColors.muted),
                ),
                const SizedBox(height: 20),
                if (state.status == TreatmentManagementStatus.loading)
                  const Center(child: CircularProgressIndicator())
                else if (state.status == TreatmentManagementStatus.failure &&
                    state.errorCode == 'ACCESS_DENIED')
                  Column(
                    children: [
                      const SizedBox(height: 40),
                      Container(
                        width: 62,
                        height: 62,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF5DB),
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFC2944D)),
                        ),
                        child: const Text(
                          '!',
                          style: TextStyle(
                            fontSize: 30,
                            color: Color(0xFFAD2E3D),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        constraints: const BoxConstraints(minHeight: 226),
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFCE8EB),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              text.tmAccessRestricted,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 21,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              text.tmAccessRestrictedBody,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 12,
                                color: TataColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed:
                              onReturnToPerson ??
                              () => Navigator.of(context).maybePop(),
                          child: Text(text.tmReturnToPerson),
                        ),
                      ),
                    ],
                  )
                else if (state.status == TreatmentManagementStatus.failure)
                  ErrorRetry(
                    message: treatmentErrorText(text, state.errorCode)!,
                    retryLabel: text.tmRetry,
                    onRetry: () =>
                        bloc.add(const TreatmentManagementRequested()),
                  )
                else ...[
                  if (knownName) ...[
                    ManagedPersonCard(
                      name: name,
                      activeMedicationCount: state.activeMedicationCount,
                      adherenceBadge: personAdherenceBadge,
                    ),
                    const SizedBox(height: 18),
                  ],
                  TreatmentManagementCard(
                    state: state,
                    onEdit: () => _editRegimen(context, state.detail!),
                    onPause: () => bloc.add(const TreatmentPauseRequested()),
                    onResume: () => bloc.add(const TreatmentResumeRequested()),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3E2),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          text.tmHistoryProtected,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          text.tmHistoryProtectedBody,
                          style: const TextStyle(
                            fontSize: 12,
                            color: TataColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (state.medication?.active == true)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        key: const Key('deactivate-treatment-medication'),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFFC72E3D),
                        ),
                        onPressed: state.busy
                            ? null
                            : () => _deactivateMedication(context),
                        child: Text(text.tmDeactivateMedication),
                      ),
                    )
                  else if (state.medicationInactive)
                    OutlinedButton(
                      onPressed: state.busy
                          ? null
                          : () => bloc.add(
                              const TreatmentMedicationReactivated(),
                            ),
                      child: Text(text.tmReactivate),
                    ),
                  if (state.errorCode != null)
                    InlineError(treatmentErrorText(text, state.errorCode)!),
                  if (adherence != null) ...[
                    const SizedBox(height: 8),
                    adherence!,
                  ],
                  if (state.detail?.status == TreatmentStatus.paused) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF5E0),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            text.tmPausedNotice,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF855E1F),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            text.tmPausedNoticeBody,
                            style: const TextStyle(
                              fontSize: 12,
                              color: TataColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
