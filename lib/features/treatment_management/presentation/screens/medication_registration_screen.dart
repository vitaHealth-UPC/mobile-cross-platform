import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/presentation/theme/tata_colors.dart';
import '../../../../shared/presentation/widgets/async_states.dart';
import '../../../../shared/presentation/widgets/status_notice.dart';
import '../../application/policies/medication_fields.dart';
import '../../application/readmodels/medication_registration_result.dart';
import '../../domain/entities/medication.dart';
import '../bloc/medication_registration/medication_registration_bloc.dart';
import '../bloc/medication_registration/medication_registration_event.dart';
import '../bloc/medication_registration/medication_registration_state.dart';
import '../texts/treatment_texts.dart';
import '../widgets/medication_registration_art.dart';
import '../widgets/treatment_visuals.dart';

/// Registers the medication identity. Treatment-specific data is entered only in setup.
class MedicationRegistrationScreen extends StatefulWidget {
  const MedicationRegistrationScreen({
    super.key,
    required this.onRegistered,
    required this.onSessionInvalidated,
    this.personName,
    this.registerInitialStock,
  });
  final ValueChanged<MedicationRegistrationResult> onRegistered;
  final VoidCallback onSessionInvalidated;
  final String? personName;

  /// Saves the optional initial stock after the medication exists; returns
  /// null on success. Absent when inventory is not available to the host.
  final Future<String?> Function(
    String medicationId, {
    required String quantity,
    required String threshold,
  })?
  registerInitialStock;

  @override
  State<MedicationRegistrationScreen> createState() =>
      _MedicationRegistrationScreenState();
}

class _MedicationRegistrationScreenState
    extends State<MedicationRegistrationScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _presentation = TextEditingController();
  final _quantity = TextEditingController();
  final _threshold = TextEditingController();
  bool _showMissingFields = false;
  bool _savingStock = false;

  bool get _missingRequired =>
      _name.text.trim().isEmpty || _presentation.text.trim().isEmpty;

  @override
  void dispose() {
    _name.dispose();
    _presentation.dispose();
    _quantity.dispose();
    _threshold.dispose();
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
    bool numeric = false,
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
      keyboardType: numeric ? TextInputType.number : null,
      inputFormatters: numeric
          ? [FilteringTextInputFormatter.digitsOnly]
          : null,
      style: const TextStyle(fontSize: 16, color: TataColors.ink),
      textCapitalization: numeric
          ? TextCapitalization.none
          : TextCapitalization.sentences,
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

  /// The medication exists; the initial stock, when typed, is saved next so
  /// the caregiver does not have to open Inventory separately.
  Future<void> _finish(Medication medication) async {
    final hook = widget.registerInitialStock;
    if (hook == null || _quantity.text.trim().isEmpty) {
      widget.onRegistered(MedicationRegistrationResult(medication: medication));
      return;
    }
    setState(() => _savingStock = true);
    final failure = await hook(
      medication.id,
      quantity: _quantity.text,
      threshold: _threshold.text.trim().isEmpty ? '0' : _threshold.text,
    );
    if (!mounted) return;
    widget.onRegistered(
      MedicationRegistrationResult(
        medication: medication,
        initialStockSaved: failure == null,
      ),
    );
  }

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
          _finish(state.medication!);
        }
      },
      builder: (context, state) {
        final locked =
            _savingStock ||
            state.status == MedicationRegistrationStatus.submitting ||
            state.status == MedicationRegistrationStatus.registered;
        final submitting =
            _savingStock ||
            state.status == MedicationRegistrationStatus.submitting;
        return PopScope(
          canPop: !submitting,
          child: Scaffold(
            backgroundColor: TataColors.background,
            body: Container(
              constraints: const BoxConstraints.expand(),
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
                  padding: const EdgeInsets.fromLTRB(22, 22, 22, 28),
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
                        TreatmentHeader(
                          title: title,
                          backLabel: text.back,
                          onBack: submitting
                              ? null
                              : () => Navigator.of(context).maybePop(),
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
                        if (widget.registerInitialStock != null) ...[
                          const SizedBox(height: 28),
                          Text(
                            text.invInitialAtRegistration,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: TataColors.ink,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            text.invInitialAtRegistrationHint,
                            style: const TextStyle(
                              fontSize: 14,
                              color: TataColors.muted,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _field(
                                  fieldKey: 'medication-initial-quantity',
                                  controller: _quantity,
                                  label: text.invInitialQuantity,
                                  hint: text.invQuantityHint,
                                  locked: locked,
                                  maxLength: 6,
                                  numeric: true,
                                  validator: (v) {
                                    final raw = v?.trim() ?? '';
                                    return raw.isEmpty ||
                                            (int.tryParse(raw) ?? 0) > 0
                                        ? null
                                        : text.invInvalidQuantity;
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _field(
                                  fieldKey: 'medication-initial-threshold',
                                  controller: _threshold,
                                  label: text.invThreshold,
                                  hint: text.invThresholdHint,
                                  locked: locked,
                                  maxLength: 6,
                                  numeric: true,
                                ),
                              ),
                            ],
                          ),
                        ],
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
                            submitting
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
