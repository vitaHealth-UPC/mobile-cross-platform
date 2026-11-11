import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/presentation/theme/tata_colors.dart';
import 'adherence_palette.dart';

/// Segments of the gauge that light up for [adherencePercent]: one for every
/// started fifth, so 92 % lights all five as the Figma sample does.
int adherenceGaugeLitSegments(int adherencePercent) =>
    (adherencePercent.clamp(0, 100) / 20).ceil();

/// Green card "Adherencia esta semana" of the Figma family summary (349 x 118):
/// the adherence of the last seven days with a short message for the caregiver
/// and a segmented gauge.
///
/// Reusable by any screen that summarises a person, such as the family summary.
/// [personName] is the name the caregiver knows the person by; the server
/// summary does not carry it.
class WeeklyAdherenceCard extends StatelessWidget {
  const WeeklyAdherenceCard({
    super.key,
    required this.adherencePercent,
    required this.personName,
  }) : assert(adherencePercent >= 0 && adherencePercent <= 100);

  /// Confirmed plus late intakes over the definitive ones, from 0 to 100.
  final int adherencePercent;
  final String personName;

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    final message = adherencePercent >= 90
        ? text.weeklyAdherenceGood(personName)
        : text.weeklyAdherenceFollowUp(personName);
    return WeeklyAdherenceFrame(
      semantics: text.weeklyAdherenceSemantics(
        personName,
        adherencePercent,
        message,
      ),
      gauge: _Gauge(percent: adherencePercent),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$adherencePercent%',
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w700,
              color: TataColors.ink,
            ),
          ),
          Text(
            message,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: TataColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}

/// Green frame with the card title and the gauge, shared by the figures and by
/// their loading, empty and failure variants so the card never changes shape.
class WeeklyAdherenceFrame extends StatelessWidget {
  const WeeklyAdherenceFrame({
    super.key,
    required this.child,
    this.gauge,
    this.semantics,
  });

  /// Content under the title.
  final Widget child;

  /// Decoration at the right; omitted while there are no figures to show.
  final Widget? gauge;

  /// One screen reader summary that replaces the visual content.
  final String? semantics;

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    final body = Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 118),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AdherencePalette.weeklyStart, AdherencePalette.weeklyEnd],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: AdherencePalette.cardShadow,
      ),
      // The Material text style (line height 1.43) is looser than Figma's.
      child: DefaultTextStyle.merge(
        style: const TextStyle(height: 1.2, letterSpacing: 0),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    text.weeklyAdherenceTitle,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AdherencePalette.weeklyTitle,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Keeps the text clear of the gauge.
                  Padding(
                    padding: EdgeInsets.only(right: gauge == null ? 0 : 112),
                    child: child,
                  ),
                ],
              ),
            ),
            if (gauge != null) Positioned(right: 13, top: 6, child: gauge!),
          ],
        ),
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

/// Five-segment arc with a heart, drawn at 112 x 84 like the Figma vector.
class _Gauge extends StatelessWidget {
  const _Gauge({required this.percent});

  final int percent;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 112,
    height: 84,
    child: CustomPaint(
      painter: _GaugePainter(adherenceGaugeLitSegments(percent)),
      child: SvgPicture.asset(
        'assets/icons/adherence_gauge_heart.svg',
        width: 112,
        height: 84,
      ),
    ),
  );
}

class _GaugePainter extends CustomPainter {
  _GaugePainter(this.lit);

  final int lit;

  /// Start and end of each segment in degrees over the top, from the left end
  /// of the arc, as measured on the Figma vector.
  static const _segments = [
    (0.0, 10.8),
    (34.2, 55.8),
    (79.2, 100.8),
    (124.2, 145.8),
    (169.2, 180.0),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCircle(center: const Offset(56, 69), radius: 42);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 11
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < _segments.length; i++) {
      final (from, to) = _segments[i];
      canvas.drawArc(
        rect,
        math.pi + from * math.pi / 180,
        (to - from) * math.pi / 180,
        false,
        stroke
          ..color = i < lit
              ? AdherencePalette.gaugeFill
              : AdherencePalette.gaugeTrack,
      );
    }
  }

  @override
  bool shouldRepaint(_GaugePainter old) => old.lit != lit;
}
