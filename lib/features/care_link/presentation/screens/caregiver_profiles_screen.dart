import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/presentation/theme/tata_typography.dart';
import '../../application/readmodels/caregiver_link_summary.dart';

/// Lists confirmed relationships and collects an explicit new profile registration.
/// No sample relatives or birth dates are prefilled into production controls.
class CaregiverProfilesScreen extends StatefulWidget {
  const CaregiverProfilesScreen({
    super.key,
    required this.links,
    required this.loading,
    required this.onRegister,
    required this.onRefresh,
    required this.onSignOut,
    this.errorText,
  });
  final List<CaregiverLinkSummary> links;
  final bool loading;
  final void Function(String, DateTime) onRegister;
  final VoidCallback onRefresh;
  final VoidCallback onSignOut;
  final String? errorText;
  @override
  State<CaregiverProfilesScreen> createState() =>
      _CaregiverProfilesScreenState();
}

/// Owns transient editable input for one registration attempt.
class _CaregiverProfilesScreenState extends State<CaregiverProfilesScreen> {
  final _name = TextEditingController();
  final _form = GlobalKey<FormState>();
  DateTime? _birthDate;
  bool _missingDate = false;
  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 28, 22, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(text.familyProfiles, style: TataTypography.heading),
                  const SizedBox(height: 12),
                  Text(
                    text.confirmedProfilesExplanation,
                    style: TataTypography.subtitle,
                  ),
                  const SizedBox(height: 20),
                  if (widget.links.isEmpty && !widget.loading)
                    Text(text.noConfirmedProfiles),
                  for (final profile in widget.links)
                    Card(
                      child: ListTile(
                        title: Text(profile.fullName),
                        subtitle: Text(text.linkConfirmed),
                      ),
                    ),
                  TextButton(
                    onPressed: widget.loading ? null : widget.onRefresh,
                    child: Text(text.refreshProfiles),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    text.registerFamilyMember,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Form(
                    key: _form,
                    child: TextFormField(
                      key: const Key('adult-name'),
                      controller: _name,
                      enabled: !widget.loading,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(labelText: text.nameLabel),
                      validator: (value) =>
                          value == null ||
                              value.trim().isEmpty ||
                              value.trim().length > 160
                          ? text.invalidAdultName
                          : null,
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: widget.loading
                        ? null
                        : () async {
                            final today = DateTime.now();
                            final date = await showDatePicker(
                              context: context,
                              initialDate: _birthDate ?? today,
                              firstDate: DateTime(1),
                              lastDate: today,
                              locale: Localizations.localeOf(context),
                            );
                            if (date != null && mounted) {
                              setState(() {
                                _birthDate = date;
                                _missingDate = false;
                              });
                            }
                          },
                    child: Text(
                      _birthDate == null
                          ? text.birthDateLabel
                          : DateFormat.yMd(
                              Localizations.localeOf(context).toString(),
                            ).format(_birthDate!),
                    ),
                  ),
                  if (_missingDate)
                    Text(
                      text.invalidBirthDate,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: widget.loading
                        ? null
                        : () {
                            final valid = _form.currentState!.validate();
                            setState(() => _missingDate = _birthDate == null);
                            if (valid && _birthDate != null) {
                              FocusScope.of(context).unfocus();
                              widget.onRegister(_name.text, _birthDate!);
                            }
                          },
                    child: Text(
                      widget.loading
                          ? text.processing
                          : text.registerFamilyMember,
                    ),
                  ),
                  if (widget.errorText != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Semantics(
                        liveRegion: true,
                        child: Text(
                          widget.errorText!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: widget.loading ? null : widget.onSignOut,
                    child: Text(text.signOut),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
