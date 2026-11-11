import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/presentation/theme/tata_colors.dart';
import '../../application/readmodels/adherence_summary.dart';
import 'adherence_labels.dart';
import 'adherence_palette.dart';

/// The three headline figures of the period: adherence, on time, late and omitted.
///
/// Cards grow with their content so a wrapped caption is never clipped, and the
/// three keep the same height.
class MetricsRow extends StatelessWidget {
  const MetricsRow({super.key, required this.summary});

  final AdherenceSummary summary;

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    final days = summary.periodDays;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _MetricCard(
              label: text.adherenceMetricAdherence,
              value: '${summary.adherencePercent}%',
              caption: adherenceChangeCaption(
                text,
                summary.adherenceChangePercent,
                days,
              ),
              start: AdherencePalette.adherenceStart,
              end: AdherencePalette.adherenceEnd,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: _MetricCard(
              label: text.adherenceMetricOnTime,
              value: '${summary.onTimePercent}%',
              caption: adherenceChangeText(summary.onTimeChangePercent),
              start: AdherencePalette.onTimeStart,
              end: AdherencePalette.onTimeEnd,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: _MetricCard(
              label: text.adherenceMetricLateOmitted,
              value: '${summary.lateCount}, ${summary.omittedCount}',
              caption: text.adherenceLateOmittedCaption(days),
              start: AdherencePalette.lateOmittedStart,
              end: AdherencePalette.lateOmittedEnd,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.caption,
    required this.start,
    required this.end,
  });

  final String label;
  final String value;
  final String? caption;
  final Color start;
  final Color end;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    label: [label, value, ?caption].join(', '),
    excludeSemantics: true,
    child: Container(
      constraints: const BoxConstraints(minHeight: 92),
      // Figma leaves about 8 px on the right: "Tardías, omitidas" is 89 px wide.
      padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [start, end]),
        borderRadius: BorderRadius.circular(16),
        boxShadow: AdherencePalette.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: TataColors.ink,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.w700,
              color: TataColors.ink,
            ),
          ),
          if (caption != null) ...[
            const SizedBox(height: 2),
            Text(
              caption!,
              style: const TextStyle(fontSize: 9, color: TataColors.deepNavy),
            ),
          ],
        ],
      ),
    ),
  );
}

/// Recurring late or omitted intakes, with the way to the recommendations.
class PatternCard extends StatelessWidget {
  const PatternCard({
    super.key,
    required this.pattern,
    required this.adherencePercent,
    required this.onOpenRecommendations,
  });

  final DetectedPattern pattern;
  final int adherencePercent;
  final VoidCallback onOpenRecommendations;

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(15, 14, 15, 0),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AdherencePalette.patternStart, AdherencePalette.patternEnd],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: AdherencePalette.cardShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: ExcludeSemantics(
              child: SvgPicture.asset(
                'assets/icons/pattern_insight_sun.svg',
                width: 22,
                height: 22,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text.adherencePatternTitle,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: TataColors.ink,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  adherencePatternHeadline(text, adherencePercent),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: TataColors.ink,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  text.adherencePatternSummary(
                    pattern.omittedCount,
                    pattern.lateCount,
                    adherenceBandLabel(text, pattern.timeBand),
                  ),
                  style: const TextStyle(
                    fontSize: 11,
                    height: 1.35,
                    color: Color(0xB30E1729),
                  ),
                ),
                InkWell(
                  onTap: onOpenRecommendations,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 44),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '${text.adherenceSeeRecommendations}  ›',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AdherencePalette.patternLink,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The three newest intakes with their definitive outcome.
class RecentIntakesCard extends StatelessWidget {
  const RecentIntakesCard({
    super.key,
    required this.intakes,
    required this.now,
  });

  final List<RecentIntake> intakes;

  /// Reference instant for "Hoy" and "Ayer".
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(13, 11, 13, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TataColors.softBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            text.adherenceRecentTitle,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: TataColors.ink,
            ),
          ),
          for (final intake in intakes) ...[
            const SizedBox(height: 12),
            _RecentRow(intake: intake, now: now),
          ],
        ],
      ),
    );
  }
}

class _RecentRow extends StatelessWidget {
  const _RecentRow({required this.intake, required this.now});

  final RecentIntake intake;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    final when = adherenceWhenLabel(context, intake.scheduledAt, now);
    final outcome = adherenceOutcomeLabel(text, intake);
    return Semantics(
      container: true,
      label: text.adherenceRecentSemantics(
        when,
        intake.medicationName,
        outcome,
      ),
      excludeSemantics: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 118,
            child: Text(
              when,
              style: const TextStyle(fontSize: 11, color: TataColors.muted),
            ),
          ),
          Expanded(
            child: Text(
              '${intake.medicationName}, $outcome',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: intake.outcome == IntakeOutcome.omitted
                    ? AdherencePalette.omittedText
                    : TataColors.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Explains that the figures follow the period the user just selected.
class PeriodUpdatedNotice extends StatelessWidget {
  const PeriodUpdatedNotice({super.key});

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: TataColors.lavender,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            text.adherencePeriodUpdatedTitle,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: TataColors.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            text.adherencePeriodUpdatedBody,
            style: const TextStyle(fontSize: 11, color: TataColors.muted),
          ),
        ],
      ),
    );
  }
}
