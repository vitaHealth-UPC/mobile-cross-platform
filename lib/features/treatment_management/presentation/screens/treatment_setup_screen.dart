import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/presentation/theme/tata_colors.dart';
import '../../../../shared/presentation/widgets/async_states.dart';
import '../bloc/treatment_setup/treatment_setup_bloc.dart';
import '../bloc/treatment_setup/treatment_setup_event.dart';
import '../bloc/treatment_setup/treatment_setup_state.dart';
import '../texts/treatment_texts.dart';
import '../widgets/treatment_setup_review.dart';
import '../widgets/treatment_stepper.dart';

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
  void initState() {
    super.initState();
    final state = context.read<TreatmentSetupBloc>().state;
    _name.text = state.treatmentName;
    _dose.text = state.dose;
    _frequency.text = state.frequency;
    _times.text = state.scheduleText;
    _instructions.text = state.instructions;
    _delay.text = state.followUpDelayMinutes?.toString() ?? '';
  }

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
        if (state.treatmentId != null && state.treatmentName != _name.text) {
          _name.text = state.treatmentName;
        }
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
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(22),
                child: Form(
                  key: _form,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            tooltip: text.back,
                            onPressed: state.loading
                                ? null
                                : () {
                                    if (state.step ==
                                        TreatmentSetupStep.details) {
                                      Navigator.of(context).maybePop();
                                    } else {
                                      bloc.add(
                                        const TreatmentSetupBackRequested(),
                                      );
                                    }
                                  },
                            icon: const Icon(
                              Icons.chevron_left,
                              color: TataColors.primary,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              text.tmSetupTitle,
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
                        text.tmSetupCaregiver,
                        style: const TextStyle(
                          fontSize: 12,
                          color: TataColors.muted,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TreatmentStepper(
                        labels: titles,
                        selected: switch (state.step) {
                          TreatmentSetupStep.details => 0,
                          TreatmentSetupStep.regimen ||
                          TreatmentSetupStep.schedule => 1,
                          TreatmentSetupStep.reminders => 2,
                          TreatmentSetupStep.review => 3,
                        },
                      ),
                      const SizedBox(height: 16),
                      if (state.step != TreatmentSetupStep.details &&
                          state.step != TreatmentSetupStep.review) ...[
                        _medication(text),
                        const SizedBox(height: 16),
                      ],
                      ..._fields(context, text, state),
                      if (state.step == TreatmentSetupStep.details) ...[
                        const SizedBox(height: 16),
                        _medication(text),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1ECFF),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Text(
                            text.tmSetupDraftHint,
                            style: const TextStyle(
                              fontSize: 13,
                              color: TataColors.muted,
                            ),
                          ),
                        ),
                      ],
                      if (state.configurationIncomplete)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF5DB),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                text.tmConfigurationIncomplete,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                text.tmCompleteConfigurationBody,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: TataColors.muted,
                                ),
                              ),
                            ],
                          ),
                        )
                      else if (error != null)
                        InlineError(error),
                      const SizedBox(height: 24),
                      _actions(context, text, state),
                      if (state.step == TreatmentSetupStep.review &&
                          state.scheduledTimes.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        TreatmentSchedulePreview(times: state.scheduledTimes),
                      ],
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
            style: const TextStyle(fontSize: 14),
            key: const Key('treatment-name'),
            controller: _name,
            enabled: !state.loading,
            readOnly: state.treatmentId != null,
            decoration: InputDecoration(labelText: text.tmTreatmentName),
            validator: (value) => _required(value, text),
          ),
        ];
      case TreatmentSetupStep.regimen:
        return [
          TextFormField(
            style: const TextStyle(fontSize: 14),
            key: const Key('treatment-dose'),
            controller: _dose,
            decoration: InputDecoration(labelText: text.tmDose),
            validator: (value) => _required(value, text),
          ),
          const SizedBox(height: 16),
          TextFormField(
            style: const TextStyle(fontSize: 14),
            key: const Key('treatment-frequency'),
            controller: _frequency,
            decoration: InputDecoration(labelText: text.tmFrequency),
            validator: (value) => _required(value, text),
          ),
        ];
      case TreatmentSetupStep.schedule:
        return [
          TextFormField(
            style: const TextStyle(fontSize: 14),
            key: const Key('treatment-times'),
            controller: _times,
            keyboardType: TextInputType.datetime,
            decoration: InputDecoration(labelText: text.tmScheduleTimes),
            validator: (value) => _required(value, text),
          ),
          const SizedBox(height: 16),
          TextFormField(
            style: const TextStyle(fontSize: 14),
            key: const Key('treatment-instructions'),
            controller: _instructions,
            maxLines: 3,
            decoration: InputDecoration(labelText: text.tmInstructions),
          ),
        ];
      case TreatmentSetupStep.reminders:
        return [
          TextFormField(
            style: const TextStyle(fontSize: 14),
            key: const Key('treatment-delay'),
            controller: _delay,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: text.tmFollowUpShort,
              helperText: text.tmFollowUpHelp,
              helperMaxLines: 4,
            ),
          ),
        ];
      case TreatmentSetupStep.review:
        return [
          TreatmentSetupReview(state: state, medication: _medication(text)),
        ];
    }
  }

  Widget _medication(AppLocalizations text) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        text.tmMedicationLabel,
        style: const TextStyle(fontSize: 11, color: TataColors.muted),
      ),
      const SizedBox(height: 8),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: const [
            BoxShadow(
              color: Color(0x141A2138),
              blurRadius: 18,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                widget.medicationLabel,
                style: const TextStyle(fontSize: 14),
              ),
            ),
            const SizedBox(width: 12),
            ExcludeSemantics(
              child: SvgPicture.asset('assets/icons/treatment_medication.svg'),
            ),
          ],
        ),
      ),
    ],
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
                  if (last && state.configurationIncomplete) {
                    bloc.add(const TreatmentConfigurationCorrectionRequested());
                    return;
                  }
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
                : last && state.configurationIncomplete
                ? text.tmCompleteConfiguration
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
