import 'package:flutter/material.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/presentation/theme/tata_typography.dart';
import '../../application/readmodels/caregiver_request.dart';

/// Adult-owned consent management; revocation requires an explicit confirmation.
class ConsentManagementScreen extends StatelessWidget {
  const ConsentManagementScreen({
    super.key,
    required this.loading,
    required this.onWithdraw,
    required this.onSignOut,
    this.errorText,
    this.requests = const [],
    this.notice,
    this.onDecide,
    this.onRemoveAccount,
  });
  final bool loading;
  final VoidCallback onWithdraw;
  final VoidCallback onSignOut;
  final String? errorText;

  /// Other caregivers waiting for this adult's decision.
  final List<CaregiverRequest> requests;
  final String? notice;
  final void Function(CaregiverRequest request, bool accepted)? onDecide;

  /// Removes the adult's account after an explicit confirmation.
  final VoidCallback? onRemoveAccount;

  Future<bool> _confirm(
    BuildContext context, {
    required String title,
    required String body,
    required String confirm,
    required String cancel,
    required Key key,
  }) async =>
      await showDialog<bool>(
        context: context,
        builder: (dialog) => AlertDialog(
          title: Text(title),
          content: Text(body),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialog).pop(false),
              child: Text(cancel),
            ),
            TextButton(
              key: key,
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(dialog).colorScheme.error,
              ),
              onPressed: () => Navigator.of(dialog).pop(true),
              child: Text(confirm),
            ),
          ],
        ),
      ) ==
      true;

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    return PopScope(
      canPop: !loading,
      child: Scaffold(
        body: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: SingleChildScrollView(
                primary: false,
                padding: const EdgeInsets.fromLTRB(22, 28, 22, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      text.consentManagementTitle,
                      style: TataTypography.heading,
                    ),
                    const SizedBox(height: 24),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        color: const Color(0xFFF1ECFF),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            text.linkConfirmed,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            text.manageConsentExplanation,
                            style: const TextStyle(fontSize: 14, height: 1.5),
                          ),
                        ],
                      ),
                    ),
                    if (notice case final message?) ...[
                      const SizedBox(height: 16),
                      Semantics(
                        liveRegion: true,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5EB),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            message,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF3A7B56),
                            ),
                          ),
                        ),
                      ),
                    ],
                    if (requests.isNotEmpty && onDecide != null) ...[
                      const SizedBox(height: 24),
                      Text(
                        text.caregiverRequestsTitle,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      for (final request in requests)
                        Container(
                          key: Key('caregiver-request-${request.careLinkId}'),
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x141A2138),
                                blurRadius: 18,
                                offset: Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                text.caregiverRequestBody(
                                  request.caregiverName ??
                                      text.caregiverRequestUnknown,
                                ),
                                style: const TextStyle(
                                  fontSize: 15,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: loading
                                          ? null
                                          : () => onDecide!(request, false),
                                      child: Text(text.caregiverRequestReject),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: ElevatedButton(
                                      key: Key(
                                        'accept-request-${request.careLinkId}',
                                      ),
                                      onPressed: loading
                                          ? null
                                          : () => onDecide!(request, true),
                                      child: Text(text.caregiverRequestAccept),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                    ],
                    const SizedBox(height: 24),
                    OutlinedButton(
                      onPressed: loading
                          ? null
                          : () async {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: Text(text.withdrawConsent),
                                  content: Text(
                                    text.withdrawConsentExplanation,
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(false),
                                      child: Text(text.keepConsent),
                                    ),
                                    TextButton(
                                      key: const Key('confirm-withdrawal'),
                                      onPressed: () =>
                                          Navigator.of(context).pop(true),
                                      child: Text(text.withdrawConsent),
                                    ),
                                  ],
                                ),
                              );
                              if (confirmed == true && context.mounted) {
                                onWithdraw();
                              }
                            },
                      child: Text(
                        loading ? text.processing : text.withdrawConsent,
                      ),
                    ),
                    if (errorText != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Semantics(
                          liveRegion: true,
                          child: Text(
                            errorText!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),
                    // Signing out and withdrawing are different decisions:
                    // say what each one does before the adult chooses.
                    Text(
                      text.consentManageSignOutHint,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.45,
                        color: Color(0xFF5B6475),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: loading ? null : onSignOut,
                      child: Text(text.signOut),
                    ),
                    if (onRemoveAccount != null) ...[
                      const SizedBox(height: 12),
                      TextButton(
                        key: const Key('remove-account'),
                        style: TextButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.error,
                        ),
                        onPressed: loading
                            ? null
                            : () async {
                                if (await _confirm(
                                      context,
                                      title: text.removeAccountTitle,
                                      body: text.removeAccountBody,
                                      confirm: text.removeAccountConfirm,
                                      cancel: text.keepConsent,
                                      key: const Key('confirm-remove-account'),
                                    ) &&
                                    context.mounted) {
                                  onRemoveAccount!();
                                }
                              },
                        child: Text(text.removeAccount),
                      ),
                    ],
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
