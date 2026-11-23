import 'package:flutter/material.dart';

/// Colors and shadows measured in the Figma history and recommendation frames.
///
/// Brand tokens such as ink, muted and primary live in `TataColors`; only the
/// tints specific to these two screens are named here.
abstract final class AdherencePalette {
  static const adherenceStart = Color(0xFFF0ECFF);
  static const adherenceEnd = Color(0xFFE7E0FC);
  static const onTimeStart = Color(0xFFECF5FB);
  static const onTimeEnd = Color(0xFFDFECF6);
  static const lateOmittedStart = Color(0xFFECF7EF);
  static const lateOmittedEnd = Color(0xFFDFF0E4);
  static const patternStart = Color(0xFFFFF3E2);
  static const patternEnd = Color(0xFFFBE8C9);
  static const patternLink = Color(0xFF5261B8);
  static const omittedText = Color(0xFFB83D47);
  static const insightStart = Color(0xFFF1ECFF);
  static const insightEnd = Color(0xFFECF4FB);
  static const heatCell = Color(0xFF0E2952);
  static const chartLabel = Color(0xFF637087);
  static const chartGrid = Color(0xCCE8E8EF);
  static const chartLine = Color(0x618B83E8);
  static const chartDot = Color(0xFF5C6ED1);
  static const chartAreaTop = Color(0x336576E6);
  static const chartAreaBottom = Color(0x006576E6);
  static const emptyStateSurface = Color(0xFFEBF5FC);
  static const emptyStateTitle = Color(0xFF121A2E);
  static const emptyStateBody = Color(0xFF78859E);
  static const outlinedAction = Color(0xFF21457A);
  static const retrySurface = Color(0xFFF0ECFF);

  /// Soft elevation shared by every card of the two screens.
  static const cardShadow = [
    BoxShadow(color: Color(0x141A2138), blurRadius: 18, offset: Offset(0, 6)),
  ];
}
