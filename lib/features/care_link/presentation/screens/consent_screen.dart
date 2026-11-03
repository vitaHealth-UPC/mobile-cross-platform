import 'package:flutter/material.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/presentation/theme/tata_typography.dart';

/// Adult decision controls based on the consent panel of Figma 563:1440.
/// Receiving an invitation is separate from approving access to follow-up data.
class ConsentScreen extends StatelessWidget {
  const ConsentScreen({
    super.key,
    required this.loading,
    required this.ready,
    required this.onDecision,
    required this.onRetry,
    required this.onSignOut,
    this.errorText,
  });
  final bool loading;
  final bool ready;
  final ValueChanged<bool> onDecision;
  final VoidCallback onRetry;
  final VoidCallback onSignOut;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    return Scaffold(
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
                  Text(text.linkTitle, style: TataTypography.heading),
                  const SizedBox(height: 8),
                  Text(text.linkSubtitle, style: TataTypography.subtitle),
                  const SizedBox(height: 28),
                  if (ready)
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        gradient: const LinearGradient(
                          colors: [Color(0xFFF1ECFF), Color(0xFFE7DFFC)],
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            text.adultConsentTitle,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            text.adultConsentExplanation,
                            style: const TextStyle(fontSize: 14, height: 1.5),
                          ),
                          const SizedBox(height: 28),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    minimumSize: const Size(0, 48),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                  ),
                                  onPressed: loading
                                      ? null
                                      : () => onDecision(true),
                                  child: Text(text.acceptLink),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    minimumSize: const Size(0, 48),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                    backgroundColor: const Color(0xFFF1ECFF),
                                    side: const BorderSide(
                                      color: Color(0xFFC2B5E5),
                                    ),
                                  ),
                                  onPressed: loading
                                      ? null
                                      : () => onDecision(false),
                                  child: Text(text.rejectLink),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  if (loading)
                    const Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  if (errorText != null) ...[
                    const SizedBox(height: 20),
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        errorText!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: loading ? null : onRetry,
                      child: Text(text.checkConsent),
                    ),
                  ],
                  const SizedBox(height: 28),
                  Text(
                    text.safeLinkTitle,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    text.safeLinkExplanation,
                    style: TataTypography.subtitle,
                  ),
                  const SizedBox(height: 24),
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
    );
  }
}
