import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/presentation/widgets/async_states.dart';
import '../bloc/treatment_setup/treatment_setup_bloc.dart';
import '../bloc/treatment_setup/treatment_setup_event.dart';
import '../bloc/treatment_setup/treatment_setup_state.dart';
import '../texts/treatment_texts.dart';

/// Wizard from a registered medication to an active treatment: details, regimen, schedule,
/// reminders and review. Field text lives here; validated values live in the bloc.
class TreatmentSetupScreen extends StatefulWidget {
  const TreatmentSetupScreen({
    super.key,
    required this.medicationLabel,
    required this.onFinished,
    required this.onSessionInvalidated,
  });

  final String medicationLabel;
  final VoidCallback onFinished;
  final VoidCallback onSessionInvalidated;

  @override
  State<TreatmentSetupScreen> createState() => _TreatmentSetupScreenState();
}

class _TreatmentSetupScreenState extends State<TreatmentSetupScreen> {
  final _name = TextEditingController();
  final _dose = TextEditingController();
  final _frequency = TextEditingController();
  final _times = TextEditingController();
  final _instructions = TextEditingController();
  final _delay = TextEditingController();
  final _form = GlobalKey<FormState>();

  @override
  void dispose() {
    for (final controller in [
      _name,
      _dose,
      _frequency,
      _times,
      _instructions,
      _delay,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    final bloc = context.read<TreatmentSetupBloc>();
    return BlocConsumer<TreatmentSetupBloc, TreatmentSetupState>(
      listener: (context, state) {
        if (isSessionFailure(state.errorCode)) {
          widget.onSessionInvalidated();
        } else if (state.activated) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(text.tmActivated)));
          widget.onFinished();
        }
      },
      builder: (context, state) {
        final titles = [
          text.tmStepDetails,
          text.tmStepRegimen,
          text.tmStepSchedule,
          text.tmStepReminders,
          text.tmStepReview,
        ];
        final error = state.configurationIncomplete
            ? text.tmErrIncomplete
            : treatmentErrorText(text, state.errorCode);
        return PopScope(
          canPop: state.step.index == 0 || state.activated,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) bloc.add(const TreatmentSetupBackRequested());
          },
          child: Scaffold(
            appBar: AppBar(title: Text(text.tmSetupTitle)),
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(22),
                child: Form(
                  key: _form,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Semantics(
                        label: '${state.step.index + 1}/${titles.length}',
                        child: LinearProgressIndicator(
                          value: (state.step.index + 1) / titles.length,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${state.step.index + 1}/${titles.length} · '
                        '${titles[state.step.index]}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(widget.medicationLabel),
                      const SizedBox(height: 20),
                      ..._fields(context, text, state),
                      if (error != null) InlineError(error),
                      const SizedBox(height: 24),
                      _actions(context, text, state),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String? _required(String? value, AppLocalizations text) =>
      value == null || value.trim().isEmpty ? text.tmRequiredField : null;

  List<Widget> _fields(
    BuildContext context,
    AppLocalizations text,
    TreatmentSetupState state,
  ) {
    switch (state.step) {
      case TreatmentSetupStep.details:
        return [
          TextFormField(
            key: const Key('treatment-name'),
            controller: _name,
            enabled: !state.loading,
            decoration: InputDecoration(labelText: text.tmTreatmentName),
            validator: (value) => _required(value, text),
          ),
        ];
      case TreatmentSetupStep.regimen:
        return [
          TextFormField(
            key: const Key('treatment-dose'),
            controller: _dose,
            decoration: InputDecoration(labelText: text.tmDose),
            validator: (value) => _required(value, text),
          ),
          const SizedBox(height: 16),
          TextFormField(
            key: const Key('treatment-frequency'),
            controller: _frequency,
            decoration: InputDecoration(labelText: text.tmFrequency),
            validator: (value) => _required(value, text),
          ),
        ];
      case TreatmentSetupStep.schedule:
        return [
          TextFormField(
            key: const Key('treatment-times'),
            controller: _times,
            keyboardType: TextInputType.datetime,
            decoration: InputDecoration(labelText: text.tmScheduleTimes),
            validator: (value) => _required(value, text),
          ),
          const SizedBox(height: 16),
          TextFormField(
            key: const Key('treatment-instructions'),
            controller: _instructions,
            maxLines: 3,
            decoration: InputDecoration(labelText: text.tmInstructions),
          ),
        ];
      case TreatmentSetupStep.reminders:
        return [
          TextFormField(
            key: const Key('treatment-delay'),
            controller: _delay,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: text.tmFollowUpDelay),
          ),
        ];
      case TreatmentSetupStep.review:
        return [
          Text(
            text.tmReviewTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          _line(text.tmTreatmentName, state.treatmentName),
          _line(text.tmDoseShort, state.dose),
          _line(text.tmFrequencyShort, state.frequency),
          _line(text.tmTimesShort, state.scheduledTimes.join(', ')),
          if (state.instructions.isNotEmpty)
            _line(text.tmInstructionsShort, state.instructions),
          _line(
            text.tmFollowUpShort,
            state.followUpDelayMinutes == null
                ? text.tmDefaultFollowUp
                : '${state.followUpDelayMinutes} min',
          ),
        ];
    }
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

  Widget _actions(
    BuildContext context,
    AppLocalizations text,
    TreatmentSetupState state,
  ) {
    final bloc = context.read<TreatmentSetupBloc>();
    final first = state.step == TreatmentSetupStep.details;
    final last = state.step == TreatmentSetupStep.review;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton(
          onPressed: state.loading
              ? null
              : () {
                  if (last) {
                    bloc.add(const TreatmentActivationRequested());
                    return;
                  }
                  if (!_form.currentState!.validate()) return;
                  FocusScope.of(context).unfocus();
                  bloc.add(switch (state.step) {
                    TreatmentSetupStep.details => TreatmentDraftSubmitted(
                      _name.text,
                    ),
                    TreatmentSetupStep.regimen => RegimenBasicsSubmitted(
                      _dose.text,
                      _frequency.text,
                    ),
                    TreatmentSetupStep.schedule => ScheduleSubmitted(
                      _times.text,
                      _instructions.text,
                    ),
                    _ => ReminderSubmitted(_delay.text),
                  });
                },
          child: Text(
            state.loading
                ? text.processing
                : last
                ? text.tmActivate
                : text.tmNext,
          ),
        ),
        if (!first && !state.activated)
          TextButton(
            onPressed: state.loading
                ? null
                : () => bloc.add(const TreatmentSetupBackRequested()),
            child: Text(text.tmBack),
          ),
      ],
    );
  }
}
