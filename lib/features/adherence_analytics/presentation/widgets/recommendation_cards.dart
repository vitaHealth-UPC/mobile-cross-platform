import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/presentation/theme/tata_colors.dart';
import '../../application/readmodels/adherence_recommendation.dart';
import 'adherence_labels.dart';
import 'adherence_palette.dart';

/// Recurring pattern in words and its concentration by time band and weekday.
class PatternHeatmapCard extends StatelessWidget {
  const PatternHeatmapCard({super.key, required this.insight});

  final AdherenceInsight insight;

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    final pattern = insight.pattern;
    final band = adherenceBandLabel(text, pattern.timeBand);
    final title = pattern.type == AdherencePatternType.lateness
        ? text.recommendationsPatternLateness(band)
        : text.recommendationsPatternOmission(band);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AdherencePalette.insightStart, AdherencePalette.insightEnd],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: AdherencePalette.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: TataColors.ink,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            adherencePatternSentence(text, pattern),
            style: const TextStyle(
              fontSize: 12,
              height: 1.5,
              color: TataColors.muted,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            text.recommendationsConcentration,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: AdherencePalette.chartLabel,
            ),
          ),
          const SizedBox(height: 14),
          Semantics(
            container: true,
            label: text.recommendationsHeatmapSemantics,
            excludeSemantics: true,
            child: Column(
              children: [
                for (var i = 0; i < insight.concentration.length; i++) ...[
                  if (i > 0) const SizedBox(height: 17),
                  _HeatRow(intensities: insight.concentration[i]),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeatRow extends StatelessWidget {
  const _HeatRow({required this.intensities});

  final List<double> intensities;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      for (var i = 0; i < intensities.length; i++) ...[
        if (i > 0) const SizedBox(width: 12),
        Expanded(
          child: Container(
            height: 7,
            decoration: BoxDecoration(
              color: AdherencePalette.heatCell.withValues(
                alpha: intensities[i].clamp(0.0, 1.0),
              ),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),
      ],
    ],
  );
}

/// One numbered follow-up action with its coloured badge.
class RecommendationCard extends StatelessWidget {
  const RecommendationCard({
    super.key,
    required this.index,
    required this.recommendation,
  });

  /// One-based position shown in the title and in the badge.
  final int index;
  final AdherenceRecommendation recommendation;

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    final (title, body) = recommendationTexts(text, recommendation);
    final heading = text.recommendationItemTitle(index, title);
    return Semantics(
      container: true,
      label: '$heading. $body',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.fromLTRB(15, 13, 15, 13),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: TataColors.softBorder),
          boxShadow: AdherencePalette.cardShadow,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    heading,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: TataColors.ink,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    body,
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.35,
                      color: TataColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            _Badge(index: index),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: 34,
    child: Stack(
      alignment: Alignment.center,
      children: [
        SvgPicture.asset(
          'assets/icons/recommendation_badge_${(index - 1) % 3 + 1}.svg',
          width: 34,
          height: 34,
        ),
        Text(
          '$index',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: TataColors.deepNavy,
          ),
        ),
      ],
    ),
  );
}

/// Primary action pinned under the recommendations ("Aplicar ajustes").
class ApplyAdjustmentsButton extends StatelessWidget {
  const ApplyAdjustmentsButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(28),
      boxShadow: AdherencePalette.cardShadow,
    ),
    child: ElevatedButton(
      onPressed: onPressed,
      child: Text(AppLocalizations.of(context).recommendationsApply),
    ),
  );
}

/// Outlined action that returns to the history ("Volver a historial").
class BackToHistoryButton extends StatelessWidget {
  const BackToHistoryButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => OutlinedButton(
    onPressed: onPressed,
    style: OutlinedButton.styleFrom(
      minimumSize: const Size(double.infinity, 50),
      foregroundColor: AdherencePalette.outlinedAction,
      side: const BorderSide(color: AdherencePalette.outlinedAction),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      // Replacing the whole style would drop the theme font (Inter).
      textStyle: Theme.of(context).textTheme.labelLarge
          ?.copyWith(fontSize: 14, fontWeight: FontWeight.w600),
    ),
    child: Text(AppLocalizations.of(context).recommendationsBack),
  );
}
