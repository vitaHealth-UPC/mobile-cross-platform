import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/application/time/clock.dart';
import '../../../../shared/presentation/theme/tata_colors.dart';
import '../../../../shared/presentation/theme/tata_typography.dart';
import '../../../../shared/presentation/widgets/caregiver_tab_bar.dart';
import '../../application/readmodels/adherence_period.dart';
import '../bloc/history/history_state.dart';
import '../widgets/adherence_feedback.dart';
import '../widgets/adherence_labels.dart';
import '../widgets/adherence_trend_chart.dart';
import '../widgets/history_cards.dart';

/// "Historial e insights": adherence figures, trend, pattern and recent
/// intakes of one older adult, for the period the caregiver selects.
///
/// Pure rendering of a [HistoryState]; every effect is a callback.
class AdherenceHistoryScreen extends StatelessWidget {
  const AdherenceHistoryScreen({
    super.key,
    required this.state,
    required this.onPeriodSelected,
    required this.onOpenRecommendations,
    required this.onRetry,
    required this.onTabSelected,
    this.clock = DateTime.now,
  });

  final HistoryState state;
  final ValueChanged<AdherencePeriod> onPeriodSelected;
  final VoidCallback onOpenRecommendations;
  final VoidCallback onRetry;
  final ValueChanged<CaregiverTab> onTabSelected;

  /// Reference for "Hoy" and "Ayer".
  final Clock clock;

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    // Figma text has no letter spacing and its natural line height (about
    // 1.2); Material adds 0.25 of spacing and a 1.43 line height to body text.
    const tight = TextStyle(letterSpacing: 0, height: 1.2);
    return Scaffold(
      backgroundColor: TataColors.background,
      // The tab bar floats over the content, as in Figma: the body runs
      // underneath it and keeps its own bottom padding to stay reachable.
      extendBody: true,
      bottomNavigationBar: DefaultTextStyle.merge(
        style: tight,
        child: CaregiverTabBar(
          selected: CaregiverTab.home,
          onSelected: onTabSelected,
        ),
      ),
      body: DefaultTextStyle.merge(
        style: tight,
        child: Stack(
          children: [
            const _BackgroundGlow(),
            SafeArea(
              bottom: false,
              child: Builder(
                // Under extendBody the padding here includes the tab bar.
                builder: (context) => SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    22,
                    16,
                    22,
                    16 + MediaQuery.paddingOf(context).bottom,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Header(
                        period: state.period,
                        onPeriodSelected: onPeriodSelected,
                      ),
                      const SizedBox(height: 14),
                      _Body(
                        state: state,
                        text: text,
                        now: clock(),
                        onOpenRecommendations: onOpenRecommendations,
                        onRetry: onRetry,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.state,
    required this.text,
    required this.now,
    required this.onOpenRecommendations,
    required this.onRetry,
  });

  final HistoryState state;
  final AppLocalizations text;
  final DateTime now;
  final VoidCallback onOpenRecommendations;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    switch (state.status) {
      case HistoryStatus.loading:
        return AdherenceLoadingCard(message: text.adherenceLoading);
      case HistoryStatus.failure:
        return AdherenceErrorCard(
          title: text.adherenceErrorTitle,
          message: adherenceErrorText(text, state.errorCode),
          onRetry: onRetry,
        );
      case HistoryStatus.insufficientData:
        return Padding(
          padding: const EdgeInsets.only(top: 98),
          child: AdherenceEmptyCard(
            title: text.adherenceInsufficientDataTitle,
            message: text.adherenceInsufficientDataBody,
          ),
        );
      case HistoryStatus.noResults:
        return Padding(
          padding: const EdgeInsets.only(top: 98),
          child: AdherenceEmptyCard(
            title: text.adherenceNoResultsTitle,
            message: text.adherenceNoResultsBody,
          ),
        );
      case HistoryStatus.content:
        final summary = state.summary!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            MetricsRow(summary: summary),
            if (summary.trend.isNotEmpty) ...[
              const SizedBox(height: 12),
              AdherenceTrendCard(points: summary.trend),
            ],
            if (summary.pattern != null) ...[
              const SizedBox(height: 12),
              PatternCard(
                pattern: summary.pattern!,
                adherencePercent: summary.adherencePercent,
                onOpenRecommendations: onOpenRecommendations,
              ),
            ],
            if (summary.recentIntakes.isNotEmpty) ...[
              const SizedBox(height: 12),
              RecentIntakesCard(intakes: summary.recentIntakes, now: now),
            ],
            if (state.periodUpdated) ...[
              const SizedBox(height: 12),
              const PeriodUpdatedNotice(),
            ],
          ],
        );
    }
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.period, required this.onPeriodSelected});

  final AdherencePeriod period;
  final ValueChanged<AdherencePeriod> onPeriodSelected;

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    Widget menu({required Widget child}) => PopupMenuButton<AdherencePeriod>(
      tooltip: text.adherencePeriodSelectorHint,
      onSelected: onPeriodSelected,
      itemBuilder: (_) => [
        for (final option in AdherencePeriod.values)
          PopupMenuItem(
            value: option,
            child: Text(text.adherencePeriodLabel(option.days)),
          ),
      ],
      child: child,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 2, top: 8),
                child: Semantics(
                  header: true,
                  child: Text(
                    text.adherenceHistoryTitle,
                    style: TataTypography.heading.copyWith(fontSize: 28),
                  ),
                ),
              ),
            ),
            menu(
              child: SizedBox.square(
                dimension: 48,
                child: Center(
                  child: SvgPicture.asset(
                    'assets/icons/history_date_range.svg',
                    width: 22,
                    height: 22,
                  ),
                ),
              ),
            ),
          ],
        ),
        menu(
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: Align(
              alignment: Alignment.centerLeft,
              widthFactor: 1,
              child: Padding(
                padding: const EdgeInsets.only(left: 2),
                child: Text(
                  '${text.adherencePeriodLabel(period.days)} ⌄',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: TataColors.deepNavy,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Soft blue glow behind the header ("Glow / Blue"). `flutter_svg` ignores the
/// blur filter of the original asset, so the same sigma is applied natively.
class _BackgroundGlow extends StatelessWidget {
  const _BackgroundGlow();

  @override
  Widget build(BuildContext context) => const Positioned(
    top: 27,
    right: -65,
    child: IgnorePointer(child: ExcludeSemantics(child: _Glow())),
  );
}

class _Glow extends StatelessWidget {
  const _Glow();

  @override
  Widget build(BuildContext context) => ImageFiltered(
    imageFilter: ImageFilter.blur(sigmaX: 29, sigmaY: 29),
    child: SvgPicture.asset(
      'assets/illustrations/history_glow_blue.svg',
      width: 396,
      height: 396,
    ),
  );
}
