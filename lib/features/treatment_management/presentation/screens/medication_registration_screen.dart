import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/presentation/theme/tata_colors.dart';
import '../../../../shared/presentation/theme/tata_typography.dart';
import '../../../../shared/presentation/widgets/async_states.dart';
import '../../application/readmodels/medication_registration_result.dart';
import '../../application/usecases/medication_usecases.dart';
import '../../domain/value_objects/regimen_text.dart';
import '../bloc/medication_registration/medication_registration_bloc.dart';
import '../bloc/medication_registration/medication_registration_event.dart';
import '../bloc/medication_registration/medication_registration_state.dart';
import '../texts/treatment_texts.dart';
import '../widgets/medication_registration_art.dart';

/// Registers medication identity and carries editable regimen text to the next route.
/// Only name and presentation are persisted here; the wizard validates the regimen.
class MedicationRegistrationScreen extends StatefulWidget {
  const MedicationRegistrationScreen({
    super.key,
    required this.onRegistered,
    required this.onSessionInvalidated,
    this.personName,
  });
  final ValueChanged<MedicationRegistrationResult> onRegistered;
  final VoidCallback onSessionInvalidated;
  final String? personName;

  @override
  State<MedicationRegistrationScreen> createState() =>
      _MedicationRegistrationScreenState();
}

class _MedicationRegistrationScreenState
    extends State<MedicationRegistrationScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _presentation = TextEditingController();
  final _frequency = TextEditingController();
  final _when = TextEditingController();
  final _notes = TextEditingController();

  String get _instructions => [
    _when.text.trim(),
    _notes.text.trim(),
  ].where((part) => part.isNotEmpty).join('\n');

  @override
  void dispose() {
    for (final controller in [
      _name,
      _presentation,
      _frequency,
      _when,
      _notes,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  String? _required(String? value, AppLocalizations text) =>
      value == null || value.trim().isEmpty ? text.tmRequiredField : null;

  Widget _field({
    required String fieldKey,
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool locked,
    required int maxLength,
    String? Function(String?)? validator,
    Widget? suffix,
    int maxLines = 1,
  }) => Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(15),
      boxShadow: const [
        BoxShadow(
          color: Color(0x141A2138),
          blurRadius: 18,
          offset: Offset(0, 6),
        ),
      ],
    ),
    child: TextFormField(
      key: Key(fieldKey),
      controller: controller,
      enabled: !locked,
      maxLength: maxLength,
      minLines: 1,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 13, color: TataColors.ink),
      textCapitalization: TextCapitalization.sentences,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        labelStyle: const TextStyle(fontSize: 14, color: TataColors.ink),
        hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF637087)),
        filled: true,
        fillColor: Colors.white,
        counterText: '',
        errorMaxLines: 3,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 13,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        suffixIcon: suffix,
      ),
      validator: validator,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    final name = widget.personName?.trim() ?? '';
    final title = name.isEmpty
        ? text.tmAddMedication
        : text.tmAddMedicationFor(name.split(RegExp(r'\s+')).first);
    return BlocConsumer<
      MedicationRegistrationBloc,
      MedicationRegistrationState
    >(
      listener: (context, state) {
        if (isSessionFailure(state.errorCode)) {
          widget.onSessionInvalidated();
        } else if (state.status == MedicationRegistrationStatus.registered &&
            state.medication != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(text.tmMedicationRegistered)));
          widget.onRegistered(
            MedicationRegistrationResult(
              medication: state.medication!,
              frequency: _frequency.text.trim(),
              instructions: _instructions,
            ),
          );
        }
      },
      builder: (context, state) {
        final locked =
            state.status == MedicationRegistrationStatus.submitting ||
            state.status == MedicationRegistrationStatus.registered;
        final submitting =
            state.status == MedicationRegistrationStatus.submitting;
        return PopScope(
          canPop: !submitting,
          child: Scaffold(
            backgroundColor: TataColors.background,
            body: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white,
                    TataColors.background,
                    Color(0xFFFCFBFF),
                  ],
                ),
              ),
              child: SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(22, 16, 22, 28),
                  child: Form(
                    key: _form,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            IconButton(
                              tooltip: text.back,
                              icon: const Icon(Icons.chevron_left),
                              onPressed: submitting
                                  ? null
                                  : () => Navigator.of(context).maybePop(),
                            ),
                            Expanded(
                              child: Text(
                                title,
                                style: TataTypography.heading.copyWith(
                                  fontSize: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          text.tmMedicationDataStep,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF637087),
                          ),
                        ),
                        const MedicationRegistrationArt(),
                        Text(
                          text.tmMedicationBasicInfo,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: TataColors.ink,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _field(
                          fieldKey: 'medication-name',
                          controller: _name,
                          label: text.tmMedicationName,
                          hint: text.tmMedicationNameHint,
                          locked: locked,
                          maxLength: maxMedicationFieldLength,
                          validator: (v) => _required(v, text),
                        ),
                        const SizedBox(height: 12),
                        _field(
                          fieldKey: 'medication-presentation',
                          controller: _presentation,
                          label: text.tmMedicationDosePresentation,
                          hint: text.tmMedicationPresentationHint,
                          locked: locked,
                          maxLength: maxMedicationFieldLength,
                          validator: (v) => _required(v, text),
                        ),
                        const SizedBox(height: 12),
                        _field(
                          fieldKey: 'medication-frequency',
                          controller: _frequency,
                          label: text.tmFrequencyShort,
                          hint: text.tmMedicationFrequencyHint,
                          locked: locked,
                          maxLength: 100,
                          validator: (v) =>
                              v == null ||
                                  v.trim().isEmpty ||
                                  Frequency.tryParse(v) != null
                              ? null
                              : text.tmErrInvalidFrequency,
                          suffix: PopupMenuButton<String>(
                            enabled: !locked,
                            tooltip: text.tmFrequencyShort,
                            icon: const Icon(
                              Icons.keyboard_arrow_down,
                              size: 20,
                            ),
                            onSelected: (value) => _frequency.text = value,
                            itemBuilder: (_) => [
                              for (final label in [
                                text.tmFrequencyDaily,
                                text.tmFrequencyTwelveHours,
                                text.tmFrequencyEightHours,
                              ])
                                PopupMenuItem(value: label, child: Text(label)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        _field(
                          fieldKey: 'medication-when',
                          controller: _when,
                          label: text.tmMedicationWhen,
                          hint: text.tmMedicationWhenHint,
                          locked: locked,
                          maxLength: 500,
                          maxLines: 2,
                        ),
                        const SizedBox(height: 12),
                        _field(
                          fieldKey: 'medication-notes',
                          controller: _notes,
                          label: text.tmMedicationNotes,
                          hint: text.tmMedicationNotesHint,
                          locked: locked,
                          maxLength: 500,
                          maxLines: 2,
                          validator: (_) =>
                              AdministrationInstructions.tryParse(
                                    _instructions,
                                  ) ==
                                  null
                              ? text.tmErrInstructionsLong
                              : null,
                        ),
                        const SizedBox(height: 32),
                        ElevatedButton(
                          onPressed: locked
                              ? null
                              : () {
                                  if (!_form.currentState!.validate()) return;
                                  FocusScope.of(context).unfocus();
                                  context
                                      .read<MedicationRegistrationBloc>()
                                      .add(
                                        MedicationSubmitted(
                                          _name.text,
                                          _presentation.text,
                                        ),
                                      );
                                },
                          child: Text(
                            state.status ==
                                    MedicationRegistrationStatus.submitting
                                ? text.processing
                                : text.tmRegistrationNext,
                          ),
                        ),
                        if (state.errorCode != null)
                          InlineError(
                            treatmentErrorText(text, state.errorCode)!,
                          ),
                        const SizedBox(height: 24),
                        ExcludeSemantics(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              for (var i = 0; i < 4; i++)
                                Container(
                                  width: i == 0 ? 10 : 8,
                                  height: i == 0 ? 10 : 8,
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: i == 0
                                        ? TataColors.primary
                                        : const Color(0xFFDADFEA),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
