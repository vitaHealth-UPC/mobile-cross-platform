import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/presentation/widgets/async_states.dart';
import '../../domain/entities/medication.dart';
import '../bloc/medication_management/medication_management_bloc.dart';
import '../bloc/medication_management/medication_management_event.dart';
import '../bloc/medication_management/medication_management_state.dart';
import '../texts/treatment_texts.dart';

/// Lists the medications of one adult with edit, deactivate/reactivate and
/// "create treatment" actions. Navigation is delegated to the route.
class MedicationManagementScreen extends StatelessWidget {
  const MedicationManagementScreen({
    super.key,
    required this.onRegister,
    required this.onCreateTreatment,
    required this.onSessionInvalidated,
    this.pickingForTreatment = false,
  });

  final VoidCallback onRegister;
  final void Function(Medication medication) onCreateTreatment;
  final VoidCallback onSessionInvalidated;

  /// True when opened to choose the medication of a new treatment.
  final bool pickingForTreatment;

  Future<void> _edit(BuildContext context, Medication medication) async {
    final text = AppLocalizations.of(context);
    final bloc = context.read<MedicationManagementBloc>();
    final name = TextEditingController(text: medication.name);
    final presentation = TextEditingController(text: medication.presentation);
    final form = GlobalKey<FormState>();
    String? required(String? value) =>
        value == null || value.trim().isEmpty ? text.tmRequiredField : null;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(text.tmEdit),
        content: Form(
          key: form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                key: const Key('edit-medication-name'),
                controller: name,
                decoration: InputDecoration(labelText: text.tmMedicationName),
                validator: required,
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('edit-medication-presentation'),
                controller: presentation,
                decoration: InputDecoration(
                  labelText: text.tmMedicationPresentation,
                ),
                validator: required,
              ),
            ],
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
    final newName = name.text;
    final newPresentation = presentation.text;
    name.dispose();
    presentation.dispose();
    if (confirmed == true) {
      bloc.add(MedicationEdited(medication.id, newName, newPresentation));
    }
  }

  Future<void> _deactivate(BuildContext context, Medication medication) async {
    final text = AppLocalizations.of(context);
    final bloc = context.read<MedicationManagementBloc>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(text.tmDeactivateTitle),
        content: Text(text.tmDeactivateBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(text.tmCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(text.tmDeactivate),
          ),
        ],
      ),
    );
    if (confirmed == true) bloc.add(MedicationDeactivated(medication.id));
  }

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    return BlocConsumer<MedicationManagementBloc, MedicationManagementState>(
      listener: (context, state) {
        if (isSessionFailure(state.errorCode)) {
          onSessionInvalidated();
          return;
        }
        final notice = state.notice;
        if (notice != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(switch (notice) {
                MedicationNotice.updated => text.tmMedicationUpdated,
                MedicationNotice.deactivated => text.tmMedicationDeactivated,
                MedicationNotice.reactivated => text.tmMedicationReactivated,
              }),
            ),
          );
        }
      },
      builder: (context, state) {
        final bloc = context.read<MedicationManagementBloc>();
        final candidates = pickingForTreatment
            ? state.medications.where((item) => item.active).toList()
            : state.medications;
        return Scaffold(
          appBar: AppBar(
            title: Text(
              pickingForTreatment
                  ? text.tmNewTreatment
                  : text.tmMedicationsTitle,
            ),
          ),
          floatingActionButton: pickingForTreatment
              ? null
              : FloatingActionButton.extended(
                  onPressed: onRegister,
                  icon: const Icon(Icons.add),
                  label: Text(text.tmRegisterMedication),
                ),
          body: switch (state.status) {
            MedicationManagementStatus.loading when state.medications.isEmpty =>
              const Center(child: CircularProgressIndicator()),
            MedicationManagementStatus.failure when state.medications.isEmpty =>
              ErrorRetry(
                message: treatmentErrorText(text, state.errorCode)!,
                retryLabel: text.tmRetry,
                onRetry: () => bloc.add(const MedicationsRequested()),
              ),
            _ => ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
              children: [
                if (pickingForTreatment)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(text.tmPickMedicationHint),
                  ),
                if (candidates.isEmpty) Text(text.tmNoMedications),
                for (final medication in candidates)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            medication.name,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(medication.presentation),
                          if (!medication.active)
                            Text(
                              text.tmInactive,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          Wrap(
                            spacing: 8,
                            children: [
                              if (medication.active)
                                TextButton(
                                  onPressed: state.busy
                                      ? null
                                      : () => onCreateTreatment(medication),
                                  child: Text(text.tmCreateTreatment),
                                ),
                              if (!pickingForTreatment) ...[
                                TextButton(
                                  onPressed: state.busy
                                      ? null
                                      : () => _edit(context, medication),
                                  child: Text(text.tmEdit),
                                ),
                                TextButton(
                                  onPressed: state.busy
                                      ? null
                                      : medication.active
                                      ? () => _deactivate(context, medication)
                                      : () => bloc.add(
                                          MedicationReactivated(medication.id),
                                        ),
                                  child: Text(
                                    medication.active
                                        ? text.tmDeactivate
                                        : text.tmReactivate,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                if (state.errorCode != null &&
                    !isSessionFailure(state.errorCode))
                  InlineError(treatmentErrorText(text, state.errorCode)!),
              ],
            ),
          },
        );
      },
    );
  }
}
