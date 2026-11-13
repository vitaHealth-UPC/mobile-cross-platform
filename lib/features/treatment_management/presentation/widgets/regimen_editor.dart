import 'package:flutter/material.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../application/readmodels/treatment_readmodels.dart';
import '../bloc/treatment_management/treatment_management_event.dart';

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
  final form = GlobalKey<FormState>();
  @override
  void initState() {
    super.initState();
    final detail = widget.detail;
    dose = TextEditingController(text: detail.dose);
    frequency = TextEditingController(text: detail.frequency);
    times = TextEditingController(text: detail.scheduledTimes.join(', '));
    instructions = TextEditingController(text: detail.instructions);
    delay = TextEditingController(
      text: detail.followUpDelayMinutes?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    for (final controller in [dose, frequency, times, instructions, delay]) {
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
                decoration: InputDecoration(
                  labelText: text.tmFollowUpShort,
                  helperText: text.tmFollowUpHelp,
                  helperMaxLines: 4,
                ),
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
