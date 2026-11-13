import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../bloc/level/level_bloc.dart';
import '../bloc/level/level_event.dart';
import '../bloc/level/level_state.dart';
import '../widgets/adherence_labels.dart';

/// Global person adherence badge; its reader is composed separately from treatment evidence.
/// Empty or unavailable evidence never becomes a zero-percent badge.
class AdherenceBadgeView extends StatefulWidget {
  const AdherenceBadgeView({
    super.key,
    required this.createBloc,
    required this.onSessionInvalidated,
  });
  final LevelBloc Function() createBloc;
  final VoidCallback onSessionInvalidated;
  @override
  State<AdherenceBadgeView> createState() => _AdherenceBadgeViewState();
}

class _AdherenceBadgeViewState extends State<AdherenceBadgeView> {
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
        if (state.status != LevelStatus.content) return const SizedBox.shrink();
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5EB),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            AppLocalizations.of(context)
                .adherencePercentBadge(state.summary!.adherencePercent),
            style: const TextStyle(fontSize: 10, color: Color(0xFF2E734D)),
          ),
        );
      },
    ),
  );
}
