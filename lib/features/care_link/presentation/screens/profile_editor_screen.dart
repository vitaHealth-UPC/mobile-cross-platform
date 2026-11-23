import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/presentation/theme/tata_typography.dart';
import '../../application/readmodels/older_adult_profile.dart';
import '../bloc/profile_editor/profile_editor_cubit.dart';

/// Native basic-data form; consent and registration ownership are not editable.
class ProfileEditorScreen extends StatelessWidget {
  const ProfileEditorScreen({super.key, required this.state});
  final ProfileEditorState state;

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    final cubit = context.read<ProfileEditorCubit>();
    final error = switch (state.errorCode) {
      null => null,
      'INVALID_NAME' => text.invalidAdultName,
      'INVALID_BIRTH_DATE' => text.invalidBirthDate,
      'NETWORK_UNAVAILABLE' => text.networkUnavailable,
      'RATE_LIMITED' => text.rateLimited,
      'ACCESS_DENIED' => text.accessDenied,
      _ => text.genericLinkError,
    };
    return PopScope(
      canPop: !state.saving,
      child: Scaffold(
        appBar: AppBar(
          leading: BackButton(
            onPressed: state.saving ? null : () => Navigator.of(context).pop(),
          ),
          title: Text(
            text.clEditProfileTitle,
            style: TataTypography.heading.copyWith(fontSize: 24),
          ),
        ),
        body: SafeArea(
          child: switch ((state.loading, state.profile)) {
            (true, _) => const Center(child: CircularProgressIndicator()),
            (false, final OlderAdultProfile profile) => _ProfileForm(
              profile: profile,
              saving: state.saving,
              error: error,
            ),
            _ => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(error ?? text.genericLinkError),
                  TextButton(onPressed: cubit.load, child: Text(text.fmRetry)),
                ],
              ),
            ),
          },
        ),
      ),
    );
  }
}

class _ProfileForm extends StatefulWidget {
  const _ProfileForm({required this.profile, required this.saving, this.error});
  final OlderAdultProfile profile;
  final bool saving;
  final String? error;

  @override
  State<_ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends State<_ProfileForm> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name;
  late DateTime _birthDate;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.profile.fullName);
    final date = widget.profile.birthDate;
    _birthDate = DateTime(date.year, date.month, date.day);
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _chooseDate() async {
    final today = DateUtils.dateOnly(DateTime.now());
    final chosen = await showDatePicker(
      context: context,
      initialDate: _birthDate.isAfter(today) ? today : _birthDate,
      firstDate: _birthDate.isBefore(DateTime(1900))
          ? _birthDate
          : DateTime(1900),
      lastDate: today,
    );
    if (mounted && chosen != null) setState(() => _birthDate = chosen);
  }

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    return Form(
      key: _form,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          TextFormField(
            controller: _name,
            enabled: !widget.saving,
            textCapitalization: TextCapitalization.words,
            maxLength: 160,
            decoration: InputDecoration(labelText: text.nameLabel),
            validator: (value) =>
                (value ?? '').trim().isEmpty ? text.invalidAdultName : null,
          ),
          const SizedBox(height: 20),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(text.birthDateLabel),
            subtitle: Text(DateFormat.yMMMd(locale).format(_birthDate)),
            trailing: const Icon(Icons.calendar_month_outlined),
            enabled: !widget.saving,
            onTap: _chooseDate,
          ),
          const SizedBox(height: 24),
          if (widget.error case final error?) ...[
            Semantics(
              liveRegion: true,
              child: Text(
                error,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
            const SizedBox(height: 16),
          ],
          FilledButton(
            onPressed: widget.saving
                ? null
                : () {
                    if (_form.currentState!.validate()) {
                      FocusScope.of(context).unfocus();
                      context.read<ProfileEditorCubit>().save(
                        _name.text,
                        _birthDate,
                      );
                    }
                  },
            child: Text(widget.saving ? text.processing : text.clSaveProfile),
          ),
        ],
      ),
    );
  }
}
