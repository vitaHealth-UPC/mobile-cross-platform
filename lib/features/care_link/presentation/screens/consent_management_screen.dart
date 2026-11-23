import 'package:flutter/material.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/presentation/theme/tata_typography.dart';

/// Adult-owned consent management; revocation requires an explicit confirmation.
class ConsentManagementScreen extends StatelessWidget {
  const ConsentManagementScreen({
    super.key,
    required this.loading,
    required this.onWithdraw,
    required this.onSignOut,
    this.errorText,
  });
  final bool loading;
  final VoidCallback onWithdraw;
  final VoidCallback onSignOut;
  final String? errorText;

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
                    TextButton(
                      onPressed: loading ? null : onSignOut,
                      child: Text(text.signOut),
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
