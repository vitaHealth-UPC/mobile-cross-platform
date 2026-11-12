import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/presentation/widgets/async_states.dart';
import '../../application/readmodels/treatment_readmodels.dart';
import '../../domain/value_objects/treatment_status.dart';
import '../bloc/treatment_management/treatment_management_bloc.dart';
import '../bloc/treatment_management/treatment_management_event.dart';
import '../bloc/treatment_management/treatment_management_state.dart';
import '../texts/treatment_texts.dart';

/// Shows one treatment and offers pause, resume, regimen editing and medication
/// availability. A draft or inactive-medication treatment is shown read-only.
class TreatmentDetailScreen extends StatelessWidget {
  const TreatmentDetailScreen({super.key, required this.onSessionInvalidated});

  final VoidCallback onSessionInvalidated;

  Future<void> _editRegimen(
    BuildContext context,
    TreatmentDetail detail,
  ) async {
    final bloc = context.read<TreatmentManagementBloc>();
    final text = AppLocalizations.of(context);
    final dose = TextEditingController(text: detail.dose);
    final frequency = TextEditingController(text: detail.frequency);
    final times = TextEditingController(text: detail.scheduledTimes.join(', '));
    final instructions = TextEditingController(text: detail.instructions);
    final delay = TextEditingController(
      text: detail.followUpDelayMinutes?.toString() ?? '',
    );
    final form = GlobalKey<FormState>();
    String? required(String? value) =>
        value == null || value.trim().isEmpty ? text.tmRequiredField : null;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(text.tmEditRegimen),
        content: SingleChildScrollView(
          child: Form(
            key: form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  key: const Key('edit-dose'),
                  controller: dose,
                  decoration: InputDecoration(labelText: text.tmDose),
                  validator: required,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('edit-frequency'),
                  controller: frequency,
                  decoration: InputDecoration(labelText: text.tmFrequency),
                  validator: required,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('edit-times'),
                  controller: times,
                  decoration: InputDecoration(labelText: text.tmScheduleTimes),
                  validator: required,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('edit-instructions'),
                  controller: instructions,
                  maxLines: 3,
                  decoration: InputDecoration(labelText: text.tmInstructions),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('edit-delay'),
                  controller: delay,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: text.tmFollowUpDelay),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(text.tmCancel),
          ),
          TextButton(
            onPressed: () {
              if (form.currentState!.validate()) {
                Navigator.pop(dialogContext, true);
              }
            },
            child: Text(text.tmSave),
          ),
        ],
      ),
    );
    final event = RegimenEdited(
      dose: dose.text,
      frequency: frequency.text,
      scheduleText: times.text,
      instructions: instructions.text,
      delayMinutes: delay.text,
    );
    for (final controller in [dose, frequency, times, instructions, delay]) {
      controller.dispose();
    }
    if (confirmed == true) bloc.add(event);
  }

  Widget _line(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Semantics(
      container: true,
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    ),
  );

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
        final detail = state.detail;
        return Scaffold(
          appBar: AppBar(title: Text(detail?.name ?? text.tmDetailTitle)),
          body: switch (state.status) {
            TreatmentManagementStatus.loading => const Center(
              child: CircularProgressIndicator(),
            ),
            TreatmentManagementStatus.failure => ErrorRetry(
              message: treatmentErrorText(text, state.errorCode)!,
              retryLabel: text.tmRetry,
              onRetry: () => bloc.add(const TreatmentManagementRequested()),
            ),
            TreatmentManagementStatus.ready => SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(22),
                children: [
                  _line(
                    text.tmDetailTitle,
                    treatmentStatusText(text, detail!.status),
                  ),
                  if (state.medication != null)
                    _line(text.tmMedicationLabel, state.medication!.label),
                  if (!state.manageable) Text(text.tmDraftIncomplete),
                  if (detail.configured) ...[
                    _line(text.tmDoseShort, detail.dose!),
                    _line(text.tmFrequencyShort, detail.frequency!),
                    _line(text.tmTimesShort, detail.scheduledTimes.join(', ')),
                    if (detail.instructions.trim().isNotEmpty)
                      _line(text.tmInstructionsShort, detail.instructions),
                    _line(
                      text.tmFollowUpShort,
                      detail.followUpDelayMinutes == null
                          ? text.tmDefaultFollowUp
                          : '${detail.followUpDelayMinutes} min',
                    ),
                  ],
                  if (state.medicationInactive) ...[
                    const SizedBox(height: 8),
                    Text(text.tmMedicationInactiveNotice),
                  ],
                  const SizedBox(height: 16),
                  if (state.manageable && !state.medicationInactive) ...[
                    if (detail.status == TreatmentStatus.active)
                      ElevatedButton(
                        onPressed: state.busy
                            ? null
                            : () => bloc.add(const TreatmentPauseRequested()),
                        child: Text(text.tmPause),
                      ),
                    if (detail.status == TreatmentStatus.paused)
                      ElevatedButton(
                        onPressed: state.busy
                            ? null
                            : () => bloc.add(const TreatmentResumeRequested()),
                        child: Text(text.tmResume),
                      ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: state.busy
                          ? null
                          : () => _editRegimen(context, detail),
                      child: Text(text.tmEditRegimen),
                    ),
                  ],
                  if (state.medicationInactive)
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
                ],
              ),
            ),
          },
        );
      },
    );
  }
}
