import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tata/features/adherence_analytics/application/readmodels/adherence_recommendation.dart';
import 'package:tata/features/adherence_analytics/application/readmodels/adherence_summary.dart';
import 'package:tata/features/adherence_analytics/application/readmodels/adherence_trend_point.dart';
import 'package:tata/l10n/generated/app_localizations.dart';
import 'package:tata/shared/presentation/theme/tata_theme.dart';

/// Reference instant of the fixtures: a Tuesday morning.
final fixtureNow = DateTime(2026, 11, 10, 9, 41);

/// Summary of thirty days shaped like the Figma "History & Insights" frame.
/// Fixture data only: production never fabricates figures.
AdherenceSummary sampleSummary({
  int periodDays = 30,
  int adherencePercent = 92,
  int? adherenceChange = 8,
  int? onTimeChange = 12,
  bool withPattern = true,
}) => AdherenceSummary(
  periodDays: periodDays,
  scheduledCount: 120,
  adherencePercent: adherencePercent,
  adherenceChangePercent: adherenceChange,
  onTimePercent: 86,
  onTimeChangePercent: onTimeChange,
  lateCount: 6,
  omittedCount: 4,
  trend: [
    for (final (offset, percent) in const [
      (0, 57),
      (5, 74),
      (10, 51),
      (15, 79),
      (20, 62),
      (25, 73),
      (30, 92),
    ])
      AdherenceTrendPoint(
        date: DateTime(2026, 10, 11 + offset),
        adherencePercent: percent,
      ),
  ],
  recentIntakes: [
    RecentIntake(
      scheduledAt: DateTime(2026, 11, 10, 8),
      medicationName: 'Losartán',
      outcome: IntakeOutcome.onTime,
    ),
    RecentIntake(
      scheduledAt: DateTime(2026, 11, 9, 20),
      medicationName: 'Amlodipino',
      outcome: IntakeOutcome.late,
      minutesLate: 24,
    ),
    RecentIntake(
      scheduledAt: DateTime(2026, 11, 7, 13),
      medicationName: 'Vitamina D3',
      outcome: IntakeOutcome.omitted,
    ),
  ],
  pattern: withPattern
      ? const DetectedPattern(
          timeBand: AdherenceTimeBand.evening,
          omittedCount: 4,
          lateCount: 6,
        )
      : null,
);

/// Insight shaped like the Figma "Adherence Recommendations" frame.
AdherenceInsight sampleInsight({
  AdherencePatternType type = AdherencePatternType.omission,
  int fromHour = 18,
  int toHour = 21,
  List<AdherenceRecommendation> recommendations = const [
    AdherenceRecommendation.adjustReminder,
    AdherenceRecommendation.reviewSchedule,
    AdherenceRecommendation.followUpOneWeek,
  ],
}) => AdherenceInsight(
  periodDays: 30,
  pattern: AdherenceInsightPattern(
    type: type,
    timeBand: AdherenceTimeBand.evening,
    omittedCount: 4,
    lateCount: 6,
    fromHour: fromHour,
    toHour: toHour,
  ),
  concentration: const [
    [0.27, 0.5, 0.72, 0.42, 0.34, 0.8, 0.64],
    [0.27, 0.42, 0.64, 0.57, 0.34, 0.72, 0.8],
    [0.19, 0.34, 0.57, 0.5, 0.27, 0.64, 0.72],
  ],
  recommendations: recommendations,
);

/// Wraps [home] with the production theme and localizations.
Widget adherenceApp(Widget home, {Locale locale = const Locale('es')}) =>
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: TataTheme.light,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: home,
    );

/// Logical 393 x 883 phone, the Figma frame, at density 3.
void useFigmaPhone(WidgetTester tester) {
  tester.view
    ..physicalSize = const Size(1179, 2649)
    ..devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}
