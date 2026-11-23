import 'package:flutter/material.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/presentation/theme/tata_colors.dart';
import 'adherence_palette.dart';

/// Light card of a legitimate empty result ("Sin datos suficientes").
class AdherenceEmptyCard extends StatelessWidget {
  const AdherenceEmptyCard({
    super.key,
    required this.title,
    required this.message,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    liveRegion: true,
    child: Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 226),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AdherencePalette.emptyStateSurface,
        borderRadius: BorderRadius.circular(20),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w600,
              color: AdherencePalette.emptyStateTitle,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              height: 1.4,
              color: AdherencePalette.emptyStateBody,
            ),
          ),
        ],
      ),
    ),
  );
}

/// Lavender card shown while a request is in flight.
class AdherenceLoadingCard extends StatelessWidget {
  const AdherenceLoadingCard({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    liveRegion: true,
    label: message,
    excludeSemantics: true,
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TataColors.lavender,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const SizedBox.square(
            dimension: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 12, color: TataColors.muted),
            ),
          ),
        ],
      ),
    ),
  );
}

/// Failure card with a retry action; the message is already translated.
class AdherenceErrorCard extends StatelessWidget {
  const AdherenceErrorCard({
    super.key,
    required this.title,
    required this.message,
    required this.onRetry,
  });

  final String title;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          container: true,
          liveRegion: true,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: TataColors.ink,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  style: const TextStyle(fontSize: 13, color: TataColors.muted),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        ElevatedButton(
          onPressed: onRetry,
          style: ElevatedButton.styleFrom(
            backgroundColor: AdherencePalette.retrySurface,
            foregroundColor: TataColors.deepNavy,
          ),
          child: Text(text.adherenceRetry),
        ),
      ],
    );
  }
}
