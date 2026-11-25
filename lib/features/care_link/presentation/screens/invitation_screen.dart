import 'package:flutter/material.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/presentation/theme/tata_typography.dart';
import '../../../../shared/presentation/widgets/status_notice.dart';

/// Collects the complete invitation without requesting a caregiver's password.
class InvitationScreen extends StatefulWidget {
  const InvitationScreen({
    super.key,
    required this.onSubmit,
    required this.loading,
    this.errorText,
    this.errorTitle,
  });
  final ValueChanged<String> onSubmit;
  final bool loading;
  final String? errorText;

  /// Names a refused invitation above [errorText] (Figma 563:2254).
  final String? errorTitle;
  @override
  State<InvitationScreen> createState() => _InvitationScreenState();
}

/// Keeps invitation text transient and disposes it when leaving the route.
class _InvitationScreenState extends State<InvitationScreen> {
  final _invitation = TextEditingController();
  @override
  void dispose() {
    _invitation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    return PopScope(
      canPop: !widget.loading,
      child: Scaffold(
        body: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 28, 22, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IconButton(
                      tooltip: text.back,
                      onPressed: widget.loading
                          ? null
                          : () => Navigator.of(context).pop(false),
                      icon: const Icon(Icons.chevron_left, size: 30),
                    ),
                    const SizedBox(height: 8),
                    Text(text.haveInvitation, style: TataTypography.heading),
                    const SizedBox(height: 12),
                    // Larger than the usual subtitle: this screen is read by
                    // the older adult.
                    Text(
                      text.invitationExplanation,
                      style: TataTypography.subtitle.copyWith(
                        fontSize: 16,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 28),
                    TextField(
                      key: const Key('care-invitation'),
                      controller: _invitation,
                      enabled: !widget.loading,
                      maxLines: 4,
                      autocorrect: false,
                      enableSuggestions: false,
                      style: const TextStyle(fontSize: 20, letterSpacing: 1),
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                        labelText: text.invitationLabel,
                      ),
                    ),
                    if (widget.errorText case final error?)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: StatusNotice(
                          title: widget.errorTitle,
                          body: error,
                        ),
                      ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: widget.loading
                          ? null
                          : () => widget.onSubmit(_invitation.text),
                      child: Text(
                        widget.loading
                            ? text.processing
                            : text.reviewInvitation,
                      ),
                    ),
                    TextButton(
                      onPressed: widget.loading
                          ? null
                          : () => Navigator.of(context).pop(false),
                      child: Text(text.backToSignIn),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
