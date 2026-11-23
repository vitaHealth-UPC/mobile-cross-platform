import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/presentation/theme/tata_colors.dart';
import 'adherence_labels.dart';
import 'adherence_palette.dart';

/// Gradient lavender card of the Figma "Level" frame (349 x 100): the adherence
/// of the last period as a ring, a level word and the change against the
/// previous period.
///
/// Reusable by any screen that shows a person's adherence, such as the person
/// profile. The ring is proportional to [adherencePercent]; Figma draws it
/// closed because its sample value is 92.
class AdherenceLevelCard extends StatelessWidget {
  const AdherenceLevelCard({
    super.key,
    required this.adherencePercent,
    required this.periodDays,
    this.changePercent,
  }) : assert(adherencePercent >= 0 && adherencePercent <= 100);

  /// Confirmed plus late intakes over the definitive ones, from 0 to 100.
  final int adherencePercent;

  /// Difference with the previous period, or null when it had no evidence.
  final int? changePercent;

  /// Length of the period the figures describe.
  final int periodDays;

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    final level = adherenceLevelLabel(text, adherencePercent);
    final caption = adherenceLevelCaption(text, changePercent, periodDays);
    return _LevelFrame(
      semantics: text.adherenceLevelSemantics(level, adherencePercent),
      child: Row(
        children: [
          _Ring(percent: adherencePercent),
          const SizedBox(width: 22),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  level,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w600,
                    color: TataColors.ink,
                  ),
                ),
                if (caption != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    caption,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AdherencePalette.chartLabel,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Lavender frame with the card title, shared by the level and by its
/// loading, empty and failure variants so the card never changes shape.
class AdherenceLevelFrame extends StatelessWidget {
  const AdherenceLevelFrame({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => _LevelFrame(child: child);
}

class _LevelFrame extends StatelessWidget {
  const _LevelFrame({required this.child, this.semantics});

  final Widget child;
  final String? semantics;

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    final body = Container(
      constraints: const BoxConstraints(minHeight: 100),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF0ECFF), Color(0xFFE6DEFB)],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: AdherencePalette.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        // Wrap the content: a host may place the card in a scrolling list.
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(
                text.adherenceLevelTitle,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: TataColors.ink,
                ),
              ),
              const SizedBox(width: 6),
              Tooltip(
                message: text.adherenceLevelInfo,
                triggerMode: TooltipTriggerMode.tap,
                child: const Icon(
                  Icons.info_outline,
                  size: 13,
                  color: TataColors.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
    if (semantics == null) return body;
    return Semantics(
      container: true,
      label: semantics,
      excludeSemantics: true,
      child: body,
    );
  }
}

/// White disc with the percentage and a 4 px arc in the Figma ring color.
class _Ring extends StatelessWidget {
  const _Ring({required this.percent});

  final int percent;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: 48,
    child: CustomPaint(
      painter: _RingPainter(percent),
      child: Center(
        child: Text(
          '$percent%',
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: TataColors.deepNavy,
          ),
        ),
      ),
    ),
  );
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.percent);

  final int percent;

  static const _ring = Color(0xFF6B78D1);

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    canvas.drawCircle(center, size.width / 2, Paint()..color = Colors.white);
    final rect = Rect.fromCircle(center: center, radius: 17);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawCircle(
      center,
      17,
      stroke..color = _ring.withValues(alpha: 0.18),
    );
    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * percent / 100,
      false,
      stroke
        ..color = _ring
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.percent != percent;
}
