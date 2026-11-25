import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/presentation/theme/tata_colors.dart';
import '../../../../shared/presentation/theme/tata_typography.dart';
import '../../../../shared/presentation/widgets/initials_avatar.dart';
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
    this.onOpenProfile,
    this.onOpenSettings,
    this.onRemove,
    this.notice,
    this.onJoin,
  });

  /// Sends another caregiver's code to care for an already registered adult.
  final ValueChanged<String>? onJoin;

  /// Ends the caregiver's link with a person, after confirmation; null hides it.
  final ValueChanged<CaregiverLinkSummary>? onRemove;

  /// Confirmation of the last change, shown in the list.
  final String? notice;

  /// Opens the caregiver's own settings; null hides the entry.
  final VoidCallback? onOpenSettings;
  final List<CaregiverLinkSummary> links;

  /// Opens what the host offers for a confirmed relationship; null hides it.
  final ValueChanged<CaregiverLinkSummary>? onOpenProfile;
  final bool loading;
  final void Function(String, DateTime) onRegister;
  final VoidCallback onRefresh;
  final VoidCallback onSignOut;
  final String? errorText;
  @override
  State<CaregiverProfilesScreen> createState() =>
      _CaregiverProfilesScreenState();
}

/// One confirmed relative, drawn with the Figma "Linked Person" patterns: a soft
/// white card, the initials avatar (never a mockup photo) and the green status
/// pill. It is actionable only when the host offers something to open.
class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.profile,
    required this.onOpen,
    this.onRemove,
  });

  final CaregiverLinkSummary profile;
  final VoidCallback? onOpen;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    final radius = BorderRadius.circular(18);
    return Semantics(
      container: true,
      button: onOpen != null,
      onTapHint: onOpen == null ? null : text.adherenceOpenFromProfile,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: radius,
          border: Border.all(color: TataColors.softBorder),
          boxShadow: const [
            BoxShadow(
              color: Color(0x141A2138),
              blurRadius: 18,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: radius,
            onTap: onOpen,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  InitialsAvatar(name: profile.fullName, size: 52),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile.fullName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: TataColors.ink,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE5F2E8),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            text.linkConfirmed,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF3D754F),
                            ),
                          ),
                        ),
                        // Whether the adult is actually using the app, not
                        // only that the link was accepted once.
                        if (profile.adultSignedIn case final signedIn?) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                Icons.circle,
                                size: 9,
                                color: signedIn
                                    ? const Color(0xFF3D754F)
                                    : TataColors.muted,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  signedIn
                                      ? text.adultStatusSignedIn
                                      : text.adultStatusSignedOut,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: TataColors.muted,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (onRemove != null)
                    PopupMenuButton<String>(
                      key: Key('family-actions-${profile.id}'),
                      tooltip: text.familyMemberActions(profile.fullName),
                      icon: const Icon(
                        Icons.more_vert,
                        color: TataColors.deepNavy,
                      ),
                      onSelected: (_) => onRemove!(),
                      itemBuilder: (_) => [
                        PopupMenuItem(
                          value: 'remove',
                          child: Text(
                            text.removeFamilyMember,
                            style: const TextStyle(color: TataColors.errorText),
                          ),
                        ),
                      ],
                    ),
                  if (onOpen != null)
                    const Icon(Icons.chevron_right, color: TataColors.deepNavy),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Owns transient editable input for one registration attempt.
class _CaregiverProfilesScreenState extends State<CaregiverProfilesScreen> {
  Future<void> _join() async {
    final code = await showDialog<String>(
      context: context,
      builder: (_) => const _JoinDialog(),
    );
    if (code != null && code.trim().isNotEmpty && mounted) {
      widget.onJoin?.call(code);
    }
  }

  Future<void> _confirmRemove(CaregiverLinkSummary profile) async {
    final text = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: Text(text.removeFamilyTitle(profile.fullName)),
        content: Text(text.removeFamilyBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog, false),
            child: Text(text.tmCancel),
          ),
          TextButton(
            key: const Key('confirm-remove-family'),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(dialog).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(dialog, true),
            child: Text(text.removeFamilyConfirm),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) widget.onRemove?.call(profile);
  }

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
                  if (widget.notice case final notice?) ...[
                    Semantics(
                      liveRegion: true,
                      child: Container(
                        key: const Key('family-notice'),
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: TataColors.mint,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          notice,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF3A7B56),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                  if (widget.links.isEmpty && !widget.loading)
                    Text(text.noConfirmedProfiles),
                  for (final profile in widget.links)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _ProfileCard(
                        profile: profile,
                        onOpen: widget.onOpenProfile == null
                            ? null
                            : () => widget.onOpenProfile!(profile),
                        onRemove: widget.onRemove == null || widget.loading
                            ? null
                            : () => _confirmRemove(profile),
                      ),
                    ),
                  TextButton(
                    onPressed: widget.loading ? null : widget.onRefresh,
                    child: Text(text.refreshProfiles),
                  ),
                  if (widget.onJoin != null)
                    OutlinedButton.icon(
                      key: const Key('join-caregiver'),
                      onPressed: widget.loading ? null : _join,
                      icon: const Icon(Icons.group_add_outlined),
                      label: Text(text.joinCaregiverButton),
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
                  if (widget.onOpenSettings != null)
                    TextButton(
                      onPressed: widget.onOpenSettings,
                      child: Text(text.pfSettings),
                    ),
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

/// Owns the code field so its controller outlives the closing animation.
class _JoinDialog extends StatefulWidget {
  const _JoinDialog();
  @override
  State<_JoinDialog> createState() => _JoinDialogState();
}

class _JoinDialogState extends State<_JoinDialog> {
  final _code = TextEditingController();

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(text.joinCaregiverTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            text.joinCaregiverHint,
            style: const TextStyle(fontSize: 13, color: TataColors.muted),
          ),
          const SizedBox(height: 14),
          TextField(
            key: const Key('join-caregiver-code'),
            controller: _code,
            autofocus: true,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(labelText: text.joinCaregiverLabel),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(text.tmCancel),
        ),
        TextButton(
          key: const Key('send-join-caregiver'),
          onPressed: () => Navigator.of(context).pop(_code.text),
          child: Text(text.joinCaregiverSend),
        ),
      ],
    );
  }
}
