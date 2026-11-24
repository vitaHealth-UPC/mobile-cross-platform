import 'package:flutter/material.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../application/readmodels/treatment_detail.dart';
import '../bloc/treatment_management/treatment_management_event.dart';
import 'prescription_fields.dart';
import 'treatment_visuals.dart';

/// Native regimen editor; its state owns controllers through the dialog exit transition.
class RegimenEditor extends StatefulWidget {
  const RegimenEditor({super.key, required this.detail});
  final TreatmentDetail detail;
  @override
  State<RegimenEditor> createState() => _RegimenEditorState();
}

class _RegimenEditorState extends State<RegimenEditor> {
  late final TextEditingController dose;
  late final TextEditingController frequency;
  late final TextEditingController times;
  late final TextEditingController instructions;
  late final TextEditingController delay;
  late final TextEditingController lead;
  final form = GlobalKey<FormState>();
  @override
  void initState() {
    super.initState();
    final detail = widget.detail;
    dose = TextEditingController(text: detail.dose);
    frequency = TextEditingController(text: detail.frequency);
    times = TextEditingController(text: detail.scheduledTimes.join(', '));
    instructions = TextEditingController(text: detail.instructions);
    lead = TextEditingController(
      text: (detail.reminderLeadMinutes ?? 0).toString(),
    );
    delay = TextEditingController(
      text: detail.followUpDelayMinutes?.toString() ?? '',
    );
  }

  bool _localizedFrequency = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_localizedFrequency) {
      _localizedFrequency = true;
      frequency.text = frequencyLabel(
        AppLocalizations.of(context),
        frequency.text,
      );
    }
  }

  @override
  void dispose() {
    for (final controller in [
      dose,
      frequency,
      times,
      instructions,
      delay,
      lead,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    String? required(String? value) =>
        value == null || value.trim().isEmpty ? text.tmRequiredField : null;
    return AlertDialog(
      title: Text(text.tmEditRegimen, style: treatmentDialogTitle(context)),
      content: SingleChildScrollView(
        child: Form(
          key: form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                key: const Key('edit-dose'),
                controller: dose,
                style: treatmentFieldStyle(context),
                maxLength: 100,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                decoration: InputDecoration(
                  labelText: text.tmDoseShort,
                  hintText: text.tmDose,
                  counterText: '',
                  suffixIcon: prescriptionOptions(
                    tooltip: text.tmDoseOptions,
                    options: [
                      text.tmDoseTablet,
                      text.tmDoseHalfTablet,
                      text.tmDoseCapsule,
                      text.tmDoseTwoTablets,
                    ],
                    controller: dose,
                  ),
                ),
                validator: required,
              ),
              const SizedBox(height: 18),
              FrequencyField(
                fieldKey: const Key('edit-frequency'),
                controller: frequency,
              ),
              const SizedBox(height: 18),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: frequency,
                builder: (_, _, _) => ScheduleTimeField(
                  fieldKey: const Key('edit-times'),
                  controller: times,
                  frequency: frequency,
                ),
              ),
              const SizedBox(height: 18),
              TextFormField(
                key: const Key('edit-instructions'),
                controller: instructions,
                style: treatmentFieldStyle(context),
                maxLines: 3,
                maxLength: 500,
                decoration: InputDecoration(
                  labelText: text.tmInstructionsShort,
                  hintText: text.tmInstructions,
                  suffixIcon: prescriptionOptions(
                    tooltip: text.tmInstructionOptions,
                    options: [
                      text.tmInstructionBeforeMeal,
                      text.tmInstructionWithMeal,
                      text.tmInstructionAfterMeal,
                      text.tmInstructionWithWater,
                    ],
                    controller: instructions,
                    append: true,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              TextFormField(
                key: const Key('edit-delay'),
                controller: delay,
                style: treatmentFieldStyle(context),
                validator: (value) {
                  final raw = value?.trim() ?? '';
                  final n = int.tryParse(raw);
                  return raw.isNotEmpty && (n == null || n < 0 || n > 1440)
                      ? text.tmErrReminderDelay
                      : null;
                },
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: text.tmFollowUpShort,
                  suffixIcon: reminderOptions(text, delay),
                  helperText: text.tmFollowUpHelp,
                  helperMaxLines: 4,
                ),
              ),
              const SizedBox(height: 18),
              TextFormField(
                key: const Key('edit-lead'),
                controller: lead,
                style: treatmentFieldStyle(context),
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: text.tmReminderLead,
                  helperText: text.tmReminderLeadHelp,
                  helperMaxLines: 3,
                ),
                validator: (value) {
                  final minutes = int.tryParse(value?.trim() ?? '');
                  return minutes == null || minutes < 0 || minutes > 1440
                      ? text.tmErrReminderLead
                      : null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(text.tmCancel),
        ),
        TextButton(
          onPressed: () {
            if (form.currentState!.validate()) {
              Navigator.pop(
                context,
                RegimenEdited(
                  dose: dose.text,
                  frequency: frequency.text,
                  scheduleText: times.text,
                  instructions: instructions.text,
                  delayMinutes: delay.text,
                  leadMinutes: lead.text,
                ),
              );
            }
          },
          child: Text(text.tmSave),
        ),
      ],
    );
  }
}
