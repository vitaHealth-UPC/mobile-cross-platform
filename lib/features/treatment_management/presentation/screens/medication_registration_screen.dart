import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/presentation/widgets/async_states.dart';
import '../bloc/medication_registration/medication_registration_bloc.dart';
import '../bloc/medication_registration/medication_registration_event.dart';
import '../bloc/medication_registration/medication_registration_state.dart';
import '../texts/treatment_texts.dart';

/// Collects the name and presentation of a new medication. Nothing is prefilled.
class MedicationRegistrationScreen extends StatefulWidget {
  const MedicationRegistrationScreen({
    super.key,
    required this.onRegistered,
    required this.onSessionInvalidated,
  });

  final VoidCallback onRegistered;
  final VoidCallback onSessionInvalidated;

  @override
  State<MedicationRegistrationScreen> createState() =>
      _MedicationRegistrationScreenState();
}

class _MedicationRegistrationScreenState
    extends State<MedicationRegistrationScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _presentation = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _presentation.dispose();
    super.dispose();
  }

  String? _required(String? value, AppLocalizations text) =>
      value == null || value.trim().isEmpty ? text.tmRequiredField : null;

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    return BlocConsumer<
      MedicationRegistrationBloc,
      MedicationRegistrationState
    >(
      listener: (context, state) {
        if (isSessionFailure(state.errorCode)) {
          widget.onSessionInvalidated();
        } else if (state.status == MedicationRegistrationStatus.registered) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(text.tmMedicationRegistered)));
          widget.onRegistered();
        }
      },
      builder: (context, state) {
        final submitting =
            state.status == MedicationRegistrationStatus.submitting;
        return Scaffold(
          appBar: AppBar(title: Text(text.tmRegisterMedication)),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(22),
              child: Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      key: const Key('medication-name'),
                      controller: _name,
                      enabled: !submitting,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        labelText: text.tmMedicationName,
                      ),
                      validator: (value) => _required(value, text),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      key: const Key('medication-presentation'),
                      controller: _presentation,
                      enabled: !submitting,
                      decoration: InputDecoration(
                        labelText: text.tmMedicationPresentation,
                      ),
                      validator: (value) => _required(value, text),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: submitting
                          ? null
                          : () {
                              if (!_form.currentState!.validate()) return;
                              FocusScope.of(context).unfocus();
                              context.read<MedicationRegistrationBloc>().add(
                                MedicationSubmitted(
                                  _name.text,
                                  _presentation.text,
                                ),
                              );
                            },
                      child: Text(
                        submitting
                            ? text.processing
                            : text.tmRegisterMedication,
                      ),
                    ),
                    if (state.errorCode != null)
                      InlineError(treatmentErrorText(text, state.errorCode)!),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
