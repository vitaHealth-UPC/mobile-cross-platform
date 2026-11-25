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
import '../widgets/prescription_fields.dart';
import '../widgets/treatment_setup_review.dart';
import '../widgets/treatment_stepper.dart';
import '../widgets/treatment_visuals.dart';

/// Text controllers of one medication's regimen.
final class _RegimenControllers {
  final dose = TextEditingController();
  final frequency = TextEditingController();
  final times = TextEditingController();
  final instructions = TextEditingController();

  void fill(SetupRegimen regimen) {
    dose.text = regimen.dose;
    frequency.text = regimen.frequency;
    times.text = regimen.scheduleText;
    instructions.text = regimen.instructions;
  }

  RegimenInput get input =>
      RegimenInput(dose.text, frequency.text, times.text, instructions.text);

  void dispose() {
    for (final controller in [dose, frequency, times, instructions]) {
      controller.dispose();
    }
  }
}

/// Wizard from registered medications to an active treatment: details (name
/// and one or more medications), one regimen per medication, reminders and
/// review. Field text lives here; validated values live in the bloc.
class TreatmentSetupScreen extends StatefulWidget {
  const TreatmentSetupScreen({
    super.key,
    required this.onFinished,
    required this.onSessionInvalidated,
    this.availableMedications = const [],
    this.initialFrequency = '',
    this.initialInstructions = '',
  });

  final VoidCallback onFinished;
  final VoidCallback onSessionInvalidated;

  /// Active medications the caregiver can add to the treatment.
  final List<SetupMedication> availableMedications;

  /// Editable text carried from registration for the first medication.
  final String initialFrequency;
  final String initialInstructions;

  @override
  State<TreatmentSetupScreen> createState() => _TreatmentSetupScreenState();
}

class _TreatmentSetupScreenState extends State<TreatmentSetupScreen> {
  final _name = TextEditingController();
  final _delay = TextEditingController();
  final _regimens = <String, _RegimenControllers>{};
  final _form = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    final state = context.read<TreatmentSetupBloc>().state;
    _name.text = state.treatmentName;
    _delay.text = state.followUpDelayMinutes?.toString() ?? '';
    for (final (index, medication) in state.medications.indexed) {
      final controllers = _controllersFor(medication.id)
        ..fill(state.regimens[medication.id] ?? const SetupRegimen());
      if (index == 0 && controllers.frequency.text.isEmpty) {
        controllers.frequency.text = widget.initialFrequency;
      }
      if (index == 0 && controllers.instructions.text.isEmpty) {
        controllers.instructions.text = widget.initialInstructions;
      }
    }
  }

  _RegimenControllers _controllersFor(String medicationId) =>
      _regimens.putIfAbsent(medicationId, _RegimenControllers.new);

  @override
  void dispose() {
    _name.dispose();
    _delay.dispose();
    for (final controllers in _regimens.values) {
      controllers.dispose();
    }
    super.dispose();
  }

  /// Single medication keeps the historical field keys (`treatment-dose`...).
  String _prefix(TreatmentSetupState state, int index) =>
      state.medications.length == 1 ? 'treatment' : 'treatment-$index';

  Future<void> _chooseMedications(TreatmentSetupState state) async {
    final text = AppLocalizations.of(context);
    final bloc = context.read<TreatmentSetupBloc>();
    final options = {
      for (final medication in widget.availableMedications)
        medication.id: medication,
      for (final medication in state.medications) medication.id: medication,
    }.values.toList();
    final chosen = await showRegimenSheet<List<SetupMedication>>(
      context,
      title: text.tmChooseMedications,
      body: (sheet) =>
          _MedicationChooser(options: options, selected: state.medications),
    );
    if (chosen != null && mounted) {
      bloc.add(TreatmentMedicationsChanged(chosen));
    }
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
            : state.errorCode == 'MEDICATION_REQUIRED'
            ? text.tmErrMedicationRequired
            : treatmentErrorText(text, state.errorCode);
        final failedMedication = state.medications
            .where((m) => m.id == state.errorMedicationId)
            .firstOrNull;
        return PopScope(
          canPop: !state.loading && (state.step.index == 0 || state.activated),
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
                      TreatmentHeader(
                        title: text.tmSetupTitle,
                        backLabel: text.back,
                        onBack: state.loading
                            ? null
                            : () {
                                if (state.step == TreatmentSetupStep.details) {
                                  Navigator.of(context).maybePop();
                                } else {
                                  bloc.add(const TreatmentSetupBackRequested());
                                }
                              },
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
                      ..._fields(context, text, state),
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
                        InlineError(
                          failedMedication != null &&
                                  state.medications.length > 1
                              ? '${failedMedication.label}: $error'
                              : error,
                        ),
                      const SizedBox(height: 24),
                      _actions(context, text, state),
                      if (state.step == TreatmentSetupStep.review &&
                          state.medications.length == 1 &&
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
        final locked = state.treatmentIds.isNotEmpty;
        return [
          TextFormField(
            style: treatmentFieldStyle(context),
            key: const Key('treatment-name'),
            controller: _name,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            enabled: !state.loading,
            readOnly: locked,
            maxLength: 160,
            decoration: InputDecoration(
              labelText: text.tmTreatmentName,
              counterText: '',
            ),
            validator: (value) => _required(value, text),
          ),
          const SizedBox(height: 16),
          Text(
            text.tmMedicationsLabel,
            style: const TextStyle(fontSize: 11, color: TataColors.muted),
          ),
          const SizedBox(height: 8),
          for (final medication in state.medications) ...[
            _medication(
              medication.label,
              onRemove: locked || state.loading
                  ? null
                  : () => context.read<TreatmentSetupBloc>().add(
                      TreatmentMedicationsChanged([
                        for (final other in state.medications)
                          if (other != medication) other,
                      ]),
                    ),
            ),
            const SizedBox(height: 10),
          ],
          if (!locked)
            OutlinedButton.icon(
              key: const Key('treatment-add-medication'),
              style: treatmentSecondaryStyle(context),
              onPressed: state.loading ? null : () => _chooseMedications(state),
              icon: const Icon(Icons.add),
              label: Text(text.tmAddMedicationToTreatment),
            ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF1ECFF),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(
              '${text.tmChooseMedicationsHint} ${text.tmSetupDraftHint}',
              style: const TextStyle(fontSize: 13, color: TataColors.muted),
            ),
          ),
          const SizedBox(height: 8),
        ];
      case TreatmentSetupStep.regimen:
      case TreatmentSetupStep.schedule:
        final several = state.medications.length > 1;
        return [
          for (final (index, medication) in state.medications.indexed) ...[
            if (several) ...[
              Text(
                '${index + 1}. ${medication.label}',
                style: treatmentSectionStyle(context),
              ),
              const SizedBox(height: 10),
            ] else ...[
              _medication(medication.label),
              const SizedBox(height: 16),
            ],
            RegimenFields(
              keyPrefix: _prefix(state, index),
              dose: _controllersFor(medication.id).dose,
              frequency: _controllersFor(medication.id).frequency,
              times: _controllersFor(medication.id).times,
              instructions: _controllersFor(medication.id).instructions,
              enabled: !state.loading,
              timeZone: index == 0
                  ? context.read<TreatmentSetupBloc>().calendarZone
                  : null,
            ),
            if (several && index < state.medications.length - 1) ...[
              const SizedBox(height: 18),
              const Divider(),
            ],
            const SizedBox(height: 18),
          ],
        ];
      case TreatmentSetupStep.reminders:
        return [
          FollowUpField(
            fieldKey: const Key('treatment-delay'),
            controller: _delay,
            enabled: !state.loading,
          ),
        ];
      case TreatmentSetupStep.review:
        return [TreatmentSetupReview(state: state)];
    }
  }

  Widget _medication(String label, {VoidCallback? onRemove}) => Container(
    padding: EdgeInsets.fromLTRB(16, 12, onRemove == null ? 16 : 4, 12),
    constraints: const BoxConstraints(minHeight: 56),
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
        Expanded(child: Text(label, style: const TextStyle(fontSize: 14))),
        const SizedBox(width: 12),
        ExcludeSemantics(
          child: SvgPicture.asset('assets/icons/treatment_medication.svg'),
        ),
        if (onRemove != null)
          IconButton(
            tooltip: AppLocalizations.of(context).tmRemoveFromTreatment,
            onPressed: onRemove,
            icon: const Icon(Icons.close),
          ),
      ],
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
                    TreatmentSetupStep.regimen ||
                    TreatmentSetupStep.schedule => TreatmentRegimensSubmitted({
                      for (final medication in state.medications)
                        medication.id: _controllersFor(medication.id).input,
                    }),
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

/// Multi-select list of the active medications.
class _MedicationChooser extends StatefulWidget {
  const _MedicationChooser({required this.options, required this.selected});
  final List<SetupMedication> options;
  final List<SetupMedication> selected;
  @override
  State<_MedicationChooser> createState() => _MedicationChooserState();
}

class _MedicationChooserState extends State<_MedicationChooser> {
  late final _chosen = [...widget.selected];

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.options.isEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              text.tmNoActiveMedications,
              style: treatmentSupportingStyle(context),
            ),
          ),
        for (final medication in widget.options)
          CheckboxListTile(
            key: Key('choose-${medication.id}'),
            value: _chosen.contains(medication),
            title: Text(medication.label, style: treatmentFieldStyle(context)),
            onChanged: (on) => setState(() {
              if (on ?? false) {
                _chosen.add(medication);
              } else {
                _chosen.remove(medication);
              }
            }),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: ElevatedButton(
            key: const Key('medications-done'),
            onPressed: () => Navigator.pop(context, _chosen),
            child: Text(text.tmMedicationsDone),
          ),
        ),
      ],
    );
  }
}
