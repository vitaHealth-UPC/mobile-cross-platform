import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/presentation/theme/tata_colors.dart';
import '../bloc/level/level_bloc.dart';
import '../bloc/level/level_event.dart';
import '../bloc/level/level_state.dart';
import '../widgets/adherence_labels.dart';
import '../widgets/adherence_level_card.dart';

/// Adherence level of one adult, loading itself for a host screen to place.
///
/// Owns and closes its [LevelBloc]. While loading, when there is not enough
/// evidence and when the read fails, the card keeps its frame and says so in
/// words; a failure offers a retry. A credential that is no longer valid is
/// reported through [onSessionInvalidated] instead of being shown.
class AdherenceLevelView extends StatefulWidget {
  const AdherenceLevelView({
    super.key,
    required this.createBloc,
    required this.onSessionInvalidated,
  });

  final LevelBloc Function() createBloc;
  final VoidCallback onSessionInvalidated;

  @override
  State<AdherenceLevelView> createState() => _AdherenceLevelViewState();
}

class _AdherenceLevelViewState extends State<AdherenceLevelView> {
  late final LevelBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = widget.createBloc()..add(const LevelRequested());
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BlocProvider.value(
    value: _bloc,
    child: BlocConsumer<LevelBloc, LevelState>(
      listenWhen: (previous, current) =>
          previous.errorCode != current.errorCode,
      listener: (context, state) {
        if (adherenceSessionLostCodes.contains(state.errorCode)) {
          widget.onSessionInvalidated();
        }
      },
      builder: (context, state) {
        final text = AppLocalizations.of(context);
        switch (state.status) {
          case LevelStatus.content:
            final summary = state.summary!;
            return AdherenceLevelCard(
              adherencePercent: summary.adherencePercent,
              changePercent: summary.adherenceChangePercent,
              periodDays: summary.periodDays,
            );
          case LevelStatus.loading:
            return AdherenceLevelFrame(
              child: Semantics(
                liveRegion: true,
                child: Row(
                  children: [
                    const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 12),
                    Text(text.adherenceLoading, style: _note),
                  ],
                ),
              ),
            );
          case LevelStatus.insufficientData:
            return AdherenceLevelFrame(
              child: Semantics(
                liveRegion: true,
                child: Text(text.adherenceInsufficientDataTitle, style: _note),
              ),
            );
          case LevelStatus.failure:
            return AdherenceLevelFrame(
              child: Semantics(
                liveRegion: true,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        adherenceErrorText(text, state.errorCode),
                        style: _note,
                      ),
                    ),
                    TextButton(
                      onPressed: () => _bloc.add(const LevelRequested()),
                      child: Text(text.adherenceRetry),
                    ),
                  ],
                ),
              ),
            );
        }
      },
    ),
  );

  static const _note = TextStyle(fontSize: 12, color: TataColors.muted);
}
