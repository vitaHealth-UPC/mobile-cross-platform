import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/presentation/theme/tata_colors.dart';
import '../../application/readmodels/adherence_summary.dart';
import '../bloc/level/level_bloc.dart';
import '../bloc/level/level_event.dart';
import '../bloc/level/level_state.dart';
import '../widgets/adherence_labels.dart';
import '../widgets/adherence_palette.dart';

/// Treatment-scoped evidence composed by the host; refreshes on foreground entry.
/// The reader must use the dedicated treatment endpoint, with no adult-summary fallback.
class TreatmentAdherenceView extends StatefulWidget {
  const TreatmentAdherenceView({
    super.key,
    required this.createBloc,
    required this.onSessionInvalidated,
  });
  final LevelBloc Function() createBloc;
  final VoidCallback onSessionInvalidated;
  @override
  State<TreatmentAdherenceView> createState() => _TreatmentAdherenceViewState();
}

class _TreatmentAdherenceViewState extends State<TreatmentAdherenceView> {
  late final LevelBloc _bloc;
  late final AppLifecycleListener _lifecycle;
  @override
  void initState() {
    super.initState();
    _bloc = widget.createBloc()..add(const LevelRequested());
    _lifecycle = AppLifecycleListener(
      onResume: () => _bloc.add(const LevelRequested()),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BlocProvider.value(
    value: _bloc,
    child: BlocConsumer<LevelBloc, LevelState>(
      listener: (_, state) {
        if (adherenceSessionLostCodes.contains(state.errorCode) ||
            state.errorCode == 'ACCESS_DENIED') {
          widget.onSessionInvalidated();
        }
      },
      builder: (context, state) {
        final text = AppLocalizations.of(context);
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF1ECFF),
            borderRadius: BorderRadius.circular(18),
            boxShadow: AdherencePalette.cardShadow,
          ),
          child: switch (state.status) {
            LevelStatus.content => TreatmentAdherenceChart(
              summary: state.summary!,
            ),
            LevelStatus.loading => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text.tmTreatmentAdherence,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                const Center(child: CircularProgressIndicator()),
              ],
            ),
            LevelStatus.insufficientData => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text.tmTreatmentAdherence,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                Text(text.adherenceInsufficientDataBody),
              ],
            ),
            LevelStatus.failure => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text.tmTreatmentAdherence,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                Text(adherenceErrorText(text, state.errorCode)),
                TextButton(
                  onPressed: () => _bloc.add(const LevelRequested()),
                  child: Text(text.tmRetry),
                ),
              ],
            ),
          },
        );
      },
    ),
  );
}

/// Native bars represent only dated points supplied by the server; zero has no filled bar.
class TreatmentAdherenceChart extends StatelessWidget {
  const TreatmentAdherenceChart({super.key, required this.summary});
  final AdherenceSummary summary;
  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                text.tmTreatmentAdherence,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${summary.adherencePercent}%',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: TataColors.primary,
              ),
            ),
          ],
        ),
        if (summary.trend.isNotEmpty) ...[
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final point in summary.trend)
                Expanded(
                  child: Semantics(
                    label:
                        '${DateFormat.yMMMd(locale).format(point.date)}, ${point.adherencePercent}%',
                    child: ExcludeSemantics(
                      child: Column(
                        children: [
                          Container(
                            width: 24,
                            height: 58,
                            clipBehavior: Clip.antiAlias,
                            decoration: BoxDecoration(
                              color: const Color(0xBFFFFFFF),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            alignment: Alignment.bottomCenter,
                            child: SizedBox(
                              width: 24,
                              height: 58 * point.adherencePercent / 100,
                              child: ColoredBox(
                                color: point.adherencePercent < 80
                                    ? const Color(0xFFC2944D)
                                    : const Color(0xFF0E2952),
                              ),
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            DateFormat.E(locale).format(point.date),
                            style: const TextStyle(
                              fontSize: 9,
                              color: TataColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}
