import 'package:flutter/material.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/presentation/theme/tata_colors.dart';
import '../../../../shared/presentation/theme/tata_typography.dart';
import '../../../../shared/presentation/widgets/caregiver_tab_bar.dart';
import '../bloc/recommendations/recommendations_state.dart';
import '../widgets/adherence_feedback.dart';
import '../widgets/adherence_labels.dart';
import '../widgets/recommendation_cards.dart';

/// "Recomendaciones": the pattern the server found and the follow-up actions it
/// recommends, never a local conclusion.
///
/// Pure rendering of a [RecommendationsState]; every effect is a callback.
/// [onApplyAdjustments] stays null until the treatment flow that receives the
/// adjustments exists, and the button is then not drawn at all.
class AdherenceRecommendationsScreen extends StatelessWidget {
  const AdherenceRecommendationsScreen({
    super.key,
    required this.state,
    required this.onBackToHistory,
    required this.onRetry,
    required this.onTabSelected,
    this.onApplyAdjustments,
  });

  final RecommendationsState state;
  final VoidCallback onBackToHistory;
  final VoidCallback onRetry;
  final ValueChanged<CaregiverTab> onTabSelected;
  final VoidCallback? onApplyAdjustments;

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    // Figma text has no letter spacing; Material adds 0.25 to body text.
    const tight = TextStyle(letterSpacing: 0, height: 1.2);
    final apply = onApplyAdjustments;
    return Scaffold(
      backgroundColor: TataColors.background,
      bottomNavigationBar: DefaultTextStyle.merge(
        style: tight,
        child: CaregiverTabBar(
          selected: CaregiverTab.home,
          onSelected: onTabSelected,
        ),
      ),
      body: DefaultTextStyle.merge(
        style: tight,
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(22, 16, 22, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 2, top: 8),
                        child: Semantics(
                          header: true,
                          child: Text(
                            text.recommendationsTitle,
                            style: TataTypography.heading,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.only(left: 2),
                        child: Text(
                          text.recommendationsSubtitle(
                            recommendationsPeriodDays,
                          ),
                          style: TataTypography.subtitle,
                        ),
                      ),
                      const SizedBox(height: 22),
                      _Body(
                        state: state,
                        text: text,
                        onBackToHistory: onBackToHistory,
                        onRetry: onRetry,
                      ),
                    ],
                  ),
                ),
              ),
              if (apply != null &&
                  state.status == RecommendationsStatus.content)
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 4, 22, 16),
                  child: ApplyAdjustmentsButton(onPressed: apply),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.state,
    required this.text,
    required this.onBackToHistory,
    required this.onRetry,
  });

  final RecommendationsState state;
  final AppLocalizations text;
  final VoidCallback onBackToHistory;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    switch (state.status) {
      case RecommendationsStatus.loading:
        return AdherenceLoadingCard(message: text.recommendationsLoading);
      case RecommendationsStatus.failure:
        return AdherenceErrorCard(
          title: text.recommendationsErrorTitle,
          message: adherenceErrorText(text, state.errorCode),
          onRetry: onRetry,
        );
      case RecommendationsStatus.insufficientEvidence:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AdherenceEmptyCard(
              title: text.recommendationsInsufficientTitle,
              message: text.recommendationsInsufficientBody,
            ),
            const SizedBox(height: 48),
            BackToHistoryButton(onPressed: onBackToHistory),
          ],
        );
      case RecommendationsStatus.content:
        final insight = state.insight!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PatternHeatmapCard(insight: insight),
            for (var i = 0; i < insight.recommendations.length; i++) ...[
              const SizedBox(height: 14),
              RecommendationCard(
                index: i + 1,
                recommendation: insight.recommendations[i],
              ),
            ],
          ],
        );
    }
  }
}
