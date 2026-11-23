import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../application/readmodels/adherence_recommendation.dart';
import '../../application/readmodels/adherence_summary.dart';

/// Localized words of the time bands; the evening is called "tarde" too, as in
/// the approved design ("por la tarde, entre 6:00 y 9:00 p. m.").
String adherenceBandLabel(AppLocalizations text, AdherenceTimeBand band) =>
    switch (band) {
      AdherenceTimeBand.morning => text.adherenceBandMorning,
      AdherenceTimeBand.afternoon ||
      AdherenceTimeBand.evening => text.adherenceBandAfternoon,
      AdherenceTimeBand.night => text.adherenceBandNight,
    };

/// Arrow, magnitude and sign of a change against the previous period, or null
/// when that period had no evidence ("↑ 8%", "↓ 3%", "= 0%").
String? adherenceChangeText(int? change) {
  if (change == null) return null;
  final arrow = change > 0
      ? '↑'
      : change < 0
      ? '↓'
      : '=';
  return '$arrow ${change.abs()}%';
}

/// Caption of the adherence card: the change and the length it compares with.
String? adherenceChangeCaption(
  AppLocalizations text,
  int? change,
  int periodDays,
) {
  final value = adherenceChangeText(change);
  return value == null
      ? null
      : text.adherenceChangeVsPrevious(value, periodDays);
}

/// Headline of the detected pattern: praise only when adherence is high.
String adherencePatternHeadline(AppLocalizations text, int adherencePercent) =>
    adherencePercent >= 90
    ? text.adherencePatternExcellent
    : text.adherencePatternAttention;

/// Outcome of a recent intake as shown next to its medication.
String adherenceOutcomeLabel(AppLocalizations text, RecentIntake intake) =>
    switch (intake.outcome) {
      IntakeOutcome.onTime => text.adherenceOutcomeOnTime,
      IntakeOutcome.late =>
        intake.minutesLate == null
            ? text.adherenceOutcomeLate
            : text.adherenceOutcomeLateMinutes(intake.minutesLate!),
      IntakeOutcome.omitted => text.adherenceOutcomeOmitted,
    };

/// "Hoy, 8:00 a. m.", "Ayer, 8:00 p. m." or "Sáb, 1:00 p. m." relative to [now].
String adherenceWhenLabel(
  BuildContext context,
  DateTime instant,
  DateTime now,
) {
  final text = AppLocalizations.of(context);
  final locale = Localizations.localeOf(context).toLanguageTag();
  final local = instant.toLocal();
  final day = DateTime(local.year, local.month, local.day);
  final today = DateTime(now.year, now.month, now.day);
  final String dayLabel;
  if (day == today) {
    dayLabel = text.adherenceDayToday;
  } else if (day == DateTime(today.year, today.month, today.day - 1)) {
    dayLabel = text.adherenceDayYesterday;
  } else {
    final short = DateFormat.E(locale).format(local).replaceAll('.', '');
    dayLabel = '${short[0].toUpperCase()}${short.substring(1)}';
  }
  return text.adherenceRecentWhen(dayLabel, _time(locale, local));
}

/// Short calendar label of a trend date, without the abbreviation period.
String adherenceDateLabel(BuildContext context, DateTime date) => DateFormat(
  'd MMM',
  Localizations.localeOf(context).toLanguageTag(),
).format(date).replaceAll('.', '');

/// Range of hours of a pattern in 12-hour time ("6:00 y 9:00 p. m.").
///
/// A shared suffix is written once; otherwise each end carries its own.
String adherenceHourRange(AppLocalizations text, int fromHour, int toHour) {
  final from = _hour(fromHour);
  final to = _hour(toHour);
  final fromSuffix = _suffix(text, fromHour);
  final toSuffix = _suffix(text, toHour);
  return fromSuffix == toSuffix
      ? text.recommendationsHourRangeShared(from, to, toSuffix)
      : text.recommendationsHourRangeSplit(from, fromSuffix, to, toSuffix);
}

/// Pattern sentence of the recommendations, ending in exactly one period.
String adherencePatternSentence(
  AppLocalizations text,
  AdherenceInsightPattern pattern,
) {
  final sentence = text.recommendationsPatternSummary(
    pattern.omittedCount,
    pattern.lateCount,
    adherenceHourRange(text, pattern.fromHour, pattern.toHour),
  );
  // "p. m." already ends with a period.
  return sentence.endsWith('.') ? sentence : '$sentence.';
}

/// Title and description of one recommended action.
(String, String) recommendationTexts(
  AppLocalizations text,
  AdherenceRecommendation recommendation,
) => switch (recommendation) {
  AdherenceRecommendation.adjustReminder => (
    text.recommendationAdjustTitle,
    text.recommendationAdjustBody,
  ),
  AdherenceRecommendation.reviewSchedule => (
    text.recommendationReviewTitle,
    text.recommendationReviewBody,
  ),
  AdherenceRecommendation.followUpOneWeek => (
    text.recommendationFollowUpTitle,
    text.recommendationFollowUpBody,
  ),
};

/// Level word of an adherence percentage. Only the 90 percent line the app
/// already uses for praise separates the two words; finer bands would be a
/// product decision the design does not make.
String adherenceLevelLabel(AppLocalizations text, int adherencePercent) =>
    adherencePercent >= 90
    ? text.adherenceLevelExcellent
    : text.adherenceLevelFollowUp;

/// Change against the previous period of the level card, named as in Figma for
/// a month ("vs. mes anterior") and a week, and by days for any other length.
String? adherenceLevelCaption(
  AppLocalizations text,
  int? change,
  int periodDays,
) {
  final value = adherenceChangeText(change);
  if (value == null) return null;
  return switch (periodDays) {
    30 => text.adherenceLevelVsMonth(value),
    7 => text.adherenceLevelVsWeek(value),
    _ => text.adherenceChangeVsPrevious(value, periodDays),
  };
}

/// Translates a stable failure code into a message safe to show.
String adherenceErrorText(AppLocalizations text, String? code) =>
    switch (code) {
      'NETWORK_UNAVAILABLE' => text.networkUnavailable,
      'RATE_LIMITED' => text.rateLimited,
      'ACCESS_DENIED' => text.accessDenied,
      _ => text.adherenceErrorBody,
    };

/// Failure codes that mean the stored credential or actor is no longer valid.
const adherenceSessionLostCodes = {
  'AUTHENTICATION_REQUIRED',
  'SESSION_CHANGED',
};

String _hour(int hour) {
  final twelve = hour % 12;
  return '${twelve == 0 ? 12 : twelve}:00';
}

String _suffix(AppLocalizations text, int hour) =>
    hour % 24 < 12 ? text.adherenceAm : text.adherencePm;

// intl separates the day period with a narrow no-break space; the design and
// the copy in the rest of the app use a plain space.
String _time(String locale, DateTime local) => DateFormat(
  'h:mm a',
  locale,
).format(local).replaceAll(' ', ' ').replaceAll(' ', ' ');
