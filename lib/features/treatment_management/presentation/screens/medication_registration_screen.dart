import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/presentation/theme/tata_colors.dart';
import '../../../../shared/presentation/theme/tata_typography.dart';
import '../../../../shared/presentation/widgets/async_states.dart';
import '../../../../shared/presentation/widgets/status_notice.dart';
import '../../application/policies/medication_fields.dart';
import '../../application/readmodels/medication_registration_result.dart';
import '../bloc/medication_registration/medication_registration_bloc.dart';
import '../bloc/medication_registration/medication_registration_event.dart';
import '../bloc/medication_registration/medication_registration_state.dart';
import '../texts/treatment_texts.dart';
import '../widgets/medication_registration_art.dart';

/// Registers the medication identity. Treatment-specific data is entered only in setup.
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
  bool _showMissingFields = false;

  bool get _missingRequired =>
      _name.text.trim().isEmpty || _presentation.text.trim().isEmpty;

  @override
  void dispose() {
    _name.dispose();
    _presentation.dispose();
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
      autovalidateMode: AutovalidateMode.onUserInteraction,
      enabled: !locked,
      maxLength: maxLength,
      minLines: 1,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 16, color: TataColors.ink),
      textCapitalization: TextCapitalization.sentences,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        labelStyle: const TextStyle(fontSize: 14, color: TataColors.ink),
        hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF637087)),
        filled: true,
        fillColor: Colors.white,
        counterText: '',
        errorMaxLines: 3,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 18,
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
            MedicationRegistrationResult(medication: state.medication!),
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
                    onChanged: () {
                      if (_showMissingFields && !_missingRequired) {
                        setState(() => _showMissingFields = false);
                      }
                    },
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
                        const MedicationRegistrationArt(),
                        Text(
                          text.tmMedicationBasicInfo,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: TataColors.ink,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          text.tmRegistrationIdentityHint,
                          style: const TextStyle(
                            fontSize: 14,
                            color: TataColors.muted,
                          ),
                        ),
                        const SizedBox(height: 24),
                        _field(
                          fieldKey: 'medication-name',
                          controller: _name,
                          label: text.tmMedicationName,
                          hint: text.tmMedicationNameHint,
                          locked: locked,
                          maxLength: maxMedicationFieldLength,
                          validator: (v) => _required(v, text),
                        ),
                        const SizedBox(height: 24),
                        _field(
                          fieldKey: 'medication-presentation',
                          controller: _presentation,
                          label: text.tmMedicationPresentationShort,
                          hint: text.tmMedicationPresentationHint,
                          locked: locked,
                          maxLength: maxMedicationFieldLength,
                          validator: (v) => _required(v, text),
                        ),
                        if (_showMissingFields) ...[
                          const SizedBox(height: 10),
                          StatusNotice(
                            key: const Key('medication-required-notice'),
                            title: text.tmMissingMedicationTitle,
                            body: text.tmMissingMedicationBody,
                          ),
                          const SizedBox(height: 12),
                        ] else
                          const SizedBox(height: 32),
                        ElevatedButton(
                          onPressed: locked
                              ? null
                              : () {
                                  final valid = _form.currentState!.validate();
                                  setState(
                                    () => _showMissingFields =
                                        !valid && _missingRequired,
                                  );
                                  if (!valid) return;
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
                                : text.tmRegistrationSaveMedication,
                          ),
                        ),
                        if (state.errorCode != null)
                          InlineError(
                            treatmentErrorText(text, state.errorCode)!,
                          ),
                        const SizedBox(height: 24),
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
