import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/presentation/widgets/async_states.dart';
import '../../domain/entities/medication.dart';
import '../bloc/medication_management/medication_management_bloc.dart';
import '../bloc/medication_management/medication_management_event.dart';
import '../bloc/medication_management/medication_management_state.dart';
import '../texts/treatment_texts.dart';
import '../widgets/medication_registration_art.dart';
import '../widgets/treatment_visuals.dart';

/// Lists the medications of one adult with edit, deactivate/reactivate and
/// "create treatment" actions. Navigation is delegated to the route.
class MedicationManagementScreen extends StatelessWidget {
  const MedicationManagementScreen({
    super.key,
    required this.onRegister,
    required this.onCreateTreatment,
    required this.onSessionInvalidated,
    this.pickingForTreatment = false,
    this.onOpenInventory,
  });

  final VoidCallback onRegister;
  final void Function(Medication medication) onCreateTreatment;
  final VoidCallback onSessionInvalidated;

  /// True when opened to choose the medication of a new treatment.
  final bool pickingForTreatment;

  /// Opens the stock of a medication; owned by the host, absent when not wired.
  final void Function(Medication medication)? onOpenInventory;

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
      builder: (dialogContext) => Theme(
        data: treatmentDialogTheme(dialogContext),
        child: AlertDialog(
          title: Text(text.tmEdit),
          content: SingleChildScrollView(
            child: Form(
              key: form,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    key: const Key('edit-medication-name'),
                    controller: name,
                    decoration: InputDecoration(
                      labelText: text.tmMedicationName,
                    ),
                    validator: required,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    key: const Key('edit-medication-presentation'),
                    controller: presentation,
                    decoration: InputDecoration(
                      labelText: text.tmMedicationPresentationShort,
                    ),
                    validator: required,
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
      builder: (dialogContext) => Theme(
        data: treatmentDialogTheme(dialogContext),
        child: AlertDialog(
          title: Text(text.tmRemoveMedicationTitle),
          content: Text(text.tmRemoveMedicationBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(text.tmCancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(text.tmRemoveMedication),
            ),
          ],
        ),
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
      },
      builder: (context, state) {
        final bloc = context.read<MedicationManagementBloc>();
        final candidates = pickingForTreatment
            ? state.medications.where((item) => item.active).toList()
            : state.medications;
        return Scaffold(
          bottomNavigationBar: candidates.isEmpty
              ? null
              : SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(22, 10, 22, 16),
                    child: ElevatedButton.icon(
                      onPressed: state.busy ? null : onRegister,
                      icon: const Icon(Icons.add),
                      label: Text(text.tmRegisterMedication),
                    ),
                  ),
                ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TreatmentHeader(
                    title: pickingForTreatment
                        ? text.tmNewTreatment
                        : text.tmMedicationsTitle,
                    backLabel: text.back,
                    onBack: state.busy
                        ? null
                        : () => Navigator.of(context).maybePop(),
                  ),
                  const SizedBox(height: 18),
                  Expanded(
                    child: switch (state.status) {
                      MedicationManagementStatus.loading
                          when state.medications.isEmpty =>
                        const Center(child: CircularProgressIndicator()),
                      MedicationManagementStatus.failure
                          when state.medications.isEmpty =>
                        ErrorRetry(
                          message: treatmentErrorText(text, state.errorCode)!,
                          retryLabel: text.tmRetry,
                          onRetry: () => bloc.add(const MedicationsRequested()),
                        ),
                      _ => ListView(
                        padding: const EdgeInsets.fromLTRB(0, 4, 0, 24),
                        children: [
                          if (state.notice case final notice?) ...[
                            TreatmentNotice(
                              key: const Key('medication-operation-receipt'),
                              message: switch (notice) {
                                MedicationNotice.registered =>
                                  text.tmMedicationRegistered,
                                MedicationNotice.updated =>
                                  text.tmMedicationUpdated,
                                MedicationNotice.deactivated =>
                                  text.tmMedicationDeactivated,
                                MedicationNotice.reactivated =>
                                  text.tmMedicationReactivated,
                                MedicationNotice.treatmentActivated =>
                                  text.tmActivated,
                              },
                              warning: notice == MedicationNotice.deactivated,
                              body: switch (notice) {
                                MedicationNotice.deactivated =>
                                  text.tmDeactivationReceipt,
                                MedicationNotice.reactivated =>
                                  text.tmReactivationReceipt,
                                _ => null,
                              },
                            ),
                            const SizedBox(height: 18),
                          ],
                          if (pickingForTreatment)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Text(text.tmPickMedicationHint),
                            ),
                          if (candidates.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 28,
                                horizontal: 12,
                              ),
                              child: Column(
                                children: [
                                  const MedicationRegistrationArt(),
                                  const SizedBox(height: 12),
                                  Text(
                                    text.tmEmptyMedicationTitle,
                                    textAlign: TextAlign.center,
                                    style: treatmentSectionStyle(context),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    text.tmEmptyMedicationBody,
                                    textAlign: TextAlign.center,
                                    style: treatmentSupportingStyle(context),
                                  ),
                                  const SizedBox(height: 24),
                                  ElevatedButton.icon(
                                    onPressed: state.busy ? null : onRegister,
                                    icon: const Icon(Icons.add),
                                    label: Text(text.tmRegisterMedication),
                                  ),
                                ],
                              ),
                            ),
                          if (!pickingForTreatment &&
                              candidates.any((m) => m.active))
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Text(
                                text.tmActiveMedicationsSection,
                                style: treatmentSectionStyle(context),
                              ),
                            ),
                          for (final medication in [
                            ...candidates.where((m) => m.active),
                            ...candidates.where((m) => !m.active),
                          ]) ...[
                            if (!medication.active &&
                                medication ==
                                    candidates.where((m) => !m.active).first)
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  0,
                                  14,
                                  0,
                                  12,
                                ),
                                child: Text(
                                  text.tmArchivedMedications,
                                  style: treatmentSectionStyle(context),
                                ),
                              ),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: TreatmentSurface(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          width: 48,
                                          height: 48,
                                          decoration: BoxDecoration(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primaryContainer,
                                            borderRadius: BorderRadius.circular(
                                              15,
                                            ),
                                          ),
                                          padding: const EdgeInsets.all(12),
                                          child: ExcludeSemantics(
                                            child: SvgPicture.asset(
                                              'assets/icons/treatment_medication.svg',
                                              colorFilter: ColorFilter.mode(
                                                Theme.of(context)
                                                    .colorScheme
                                                    .primary,
                                                BlendMode.srcIn,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                medication.name,
                                                style: treatmentSectionStyle(
                                                  context,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                medication.presentation,
                                                style: treatmentSupportingStyle(
                                                  context,
                                                ),
                                              ),
                                              if (!medication.active) ...[
                                                const SizedBox(height: 8),
                                                Align(
                                                  alignment:
                                                      Alignment.centerLeft,
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 10,
                                                          vertical: 5,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .errorContainer,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            20,
                                                          ),
                                                    ),
                                                    child: Text(
                                                      text.tmInactive,
                                                      style: TextStyle(
                                                        fontFamily: 'Inter',
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .onErrorContainer,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (medication.active) ...[
                                      const SizedBox(height: 18),
                                      TextButton(
                                        style: TextButton.styleFrom(
                                          backgroundColor: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                          foregroundColor: Theme.of(context)
                                              .colorScheme
                                              .onPrimary,
                                          minimumSize: const Size(
                                            double.infinity,
                                            48,
                                          ),
                                          shape: const StadiumBorder(),
                                          textStyle: const TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        onPressed: state.busy
                                            ? null
                                            : () =>
                                                  onCreateTreatment(medication),
                                        child: Text(
                                          text.tmCreateTreatment,
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ],
                                    if (!pickingForTreatment) ...[
                                      const SizedBox(height: 12),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: [
                                          if (onOpenInventory case final open?)
                                            OutlinedButton(
                                              style: treatmentSecondaryStyle(
                                                context,
                                              ),
                                              onPressed: state.busy
                                                  ? null
                                                  : () => open(medication),
                                              child: Text(text.invTitle),
                                            ),
                                          OutlinedButton(
                                            style: treatmentSecondaryStyle(
                                              context,
                                            ),
                                            onPressed: state.busy
                                                ? null
                                                : () => _edit(
                                                    context,
                                                    medication,
                                                  ),
                                            child: Text(text.tmEdit),
                                          ),
                                          OutlinedButton(
                                            style: treatmentSecondaryStyle(
                                              context,
                                            ),
                                            onPressed: state.busy
                                                ? null
                                                : medication.active
                                                ? () => _deactivate(
                                                    context,
                                                    medication,
                                                  )
                                                : () => bloc.add(
                                                    MedicationReactivated(
                                                      medication.id,
                                                    ),
                                                  ),
                                            child: Text(
                                              medication.active
                                                  ? text.tmRemoveMedication
                                                  : text.tmReactivate,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ],
                          if (state.errorCode != null &&
                              !isSessionFailure(state.errorCode))
                            InlineError(
                              treatmentErrorText(text, state.errorCode)!,
                            ),
                        ],
                      ),
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
