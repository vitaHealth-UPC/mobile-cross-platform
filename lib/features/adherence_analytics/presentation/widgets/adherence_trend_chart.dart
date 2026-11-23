import 'package:flutter/material.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/presentation/theme/tata_colors.dart';
import '../../application/readmodels/adherence_trend_point.dart';
import 'adherence_labels.dart';
import 'adherence_palette.dart';

/// Geometry of the "Chart" card of the Figma history frame (349 x 246).
abstract final class _Plot {
  static const left = 52.0;
  static const rightInset = 25.0;
  static const plotHeight = 144.0;
  static const axisSpace = 40.0;

  /// Points stop short of the grid end, as drawn in Figma (x = 305 of 324).
  static const pointsEndInset = 19.0;
  static const pointInset = 3.0;
  static const maxAxisLabels = 5;
}

/// Adherence over the period: a line with its area, a percentage grid and the
/// latest value. Points sit proportionally to their dates.
class AdherenceTrendCard extends StatelessWidget {
  const AdherenceTrendCard({super.key, required this.points})
    : assert(points.length > 0);

  final List<AdherenceTrendPoint> points;

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    final latest = points.last;
    final latestLabel = adherenceDateLabel(context, latest.date);
    final largeText = MediaQuery.textScalerOf(context).scale(9) > 12;
    final labelWidth = largeText ? 60.0 : 40.0;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AdherencePalette.cardShadow,
      ),
      child: Semantics(
        container: true,
        label: text.adherenceTrendSemantics(
          latest.adherencePercent,
          latestLabel,
        ),
        excludeSemantics: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 25, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            text.adherenceTrendTitle,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: TataColors.ink,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Tooltip(
                          message: text.adherenceTrendInfo,
                          triggerMode: TooltipTriggerMode.tap,
                          child: const Icon(
                            Icons.info_outline,
                            size: 14,
                            color: TataColors.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: largeText ? 90 : 65,
                    child: Text(
                      '${latest.adherencePercent}%\n$latestLabel',
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 11,
                        height: 1.2,
                        fontWeight: FontWeight.w500,
                        color: TataColors.deepNavy,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              height: _Plot.plotHeight + _Plot.axisSpace,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final xs = _positions(points, constraints.maxWidth);
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      for (final percent in const [100, 75, 50, 25, 0])
                        Positioned(
                          left: 10,
                          top: _y(percent) - 8,
                          child: Text('$percent%', style: _axisStyle),
                        ),
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _TrendPainter(points: points, xs: xs),
                        ),
                      ),
                      for (final index in _labelIndexes(
                        points.length,
                        maxLabels: largeText ? 3 : _Plot.maxAxisLabels,
                      ))
                        Positioned(
                          left: xs[index] - labelWidth / 2,
                          width: labelWidth,
                          top: _Plot.plotHeight + 8,
                          child: Text(
                            adherenceDateLabel(context, points[index].date),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            style: _axisStyle,
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  static const _axisStyle = TextStyle(
    fontSize: 9,
    color: AdherencePalette.chartLabel,
  );

  static double _y(num percent) => _Plot.plotHeight * (1 - percent / 100);

  /// Horizontal centre of each point, proportional to its date.
  static List<double> _positions(List<AdherenceTrendPoint> points, double w) {
    final start = _Plot.left + _Plot.pointInset;
    final end = w - _Plot.rightInset - _Plot.pointsEndInset;
    final first = points.first.date;
    final span = points.last.date.difference(first).inHours;
    return [
      for (final point in points)
        span == 0
            ? (start + end) / 2
            : start +
                  (end - start) * point.date.difference(first).inHours / span,
    ];
  }

  /// At most five evenly spread points carry an axis label.
  static List<int> _labelIndexes(
    int count, {
    int maxLabels = _Plot.maxAxisLabels,
  }) {
    if (count <= maxLabels) return List.generate(count, (i) => i);
    return {
      for (var i = 0; i < maxLabels; i++)
        (i * (count - 1) / (maxLabels - 1)).round(),
    }.toList();
  }
}

class _TrendPainter extends CustomPainter {
  _TrendPainter({required this.points, required this.xs});

  final List<AdherenceTrendPoint> points;
  final List<double> xs;

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = AdherencePalette.chartGrid
      ..strokeWidth = 1;
    final right = size.width - _Plot.rightInset;
    for (final percent in const [100, 75, 50, 25, 0]) {
      final y = AdherenceTrendCard._y(percent);
      canvas.drawLine(Offset(_Plot.left, y), Offset(right, y), gridPaint);
    }
    final offsets = [
      for (var i = 0; i < points.length; i++)
        Offset(xs[i], AdherenceTrendCard._y(points[i].adherencePercent)),
    ];
    final line = Path()..moveTo(offsets.first.dx, offsets.first.dy);
    for (final offset in offsets.skip(1)) {
      line.lineTo(offset.dx, offset.dy);
    }
    final area = Path.from(line)
      ..lineTo(offsets.last.dx, _Plot.plotHeight)
      ..lineTo(offsets.first.dx, _Plot.plotHeight)
      ..close();
    final highest = offsets.map((o) => o.dy).reduce((a, b) => a < b ? a : b);
    canvas.drawPath(
      area,
      Paint()
        ..shader =
            const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AdherencePalette.chartAreaTop,
                AdherencePalette.chartAreaBottom,
              ],
            ).createShader(
              Rect.fromLTRB(_Plot.left, highest, right, _Plot.plotHeight),
            ),
    );
    if (offsets.length > 1) {
      canvas.drawPath(
        line,
        Paint()
          ..color = AdherencePalette.chartLine
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }
    final dot = Paint()..color = AdherencePalette.chartDot;
    for (final offset in offsets) {
      canvas.drawCircle(offset, 3, dot);
    }
  }

  @override
  bool shouldRepaint(_TrendPainter old) => old.points != points || old.xs != xs;
}
