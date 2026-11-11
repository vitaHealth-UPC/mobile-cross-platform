import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/presentation/theme/tata_colors.dart';
import '../../../../shared/presentation/widgets/initials_avatar.dart';
import '../../application/readmodels/intake_sync_status.dart';
import '../../domain/entities/intake.dart';
import '../bloc/home/home_state.dart';
import '../widgets/adult_navigation_bar.dart';
import '../widgets/home_cards.dart';

/// Figma 563:58 adult home. Unconnected actions retain their layout and are disabled explicitly.
class AdultHomeScreen extends StatefulWidget {
  const AdultHomeScreen({
    super.key,
    required this.state,
    required this.adultName,
    required this.clock,
    required this.onRefresh,
    required this.onOpenMore,
    this.errorText,
    this.onOpenVoice,
    this.onOpenAgenda,
    this.onOpenDose,
    this.syncStatus,
  });

  final HomeState state;
  final String? adultName;
  final DateTime Function() clock;
  final Future<void> Function() onRefresh;

  /// Opens account actions such as consent management and switching account.
  final VoidCallback onOpenMore;
  final String? errorText;

  /// Shown only when stored data is in use or confirmations are unsent.
  final IntakeSyncStatus? syncStatus;
  final ValueChanged<String>? onOpenVoice;
  final VoidCallback? onOpenAgenda;

  /// Opens the detail of one dose, where it can be confirmed.
  final ValueChanged<String>? onOpenDose;

  @override
  State<AdultHomeScreen> createState() => _AdultHomeScreenState();
}

class _AdultHomeScreenState extends State<AdultHomeScreen> {
  bool _showTip = true;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    // Keeps "in N min" and the date current while the screen stays open.
    _ticker = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    final now = widget.clock();
    final locale = Localizations.localeOf(context).toLanguageTag();
    final date = DateFormat.MMMMEEEEd(locale).format(now);
    final state = widget.state;
    final next = state.next;
    return Scaffold(
      bottomNavigationBar: AdultNavigationBar(
        selected: AdultDestination.home,
        onAgenda: widget.onOpenAgenda,
        onMore: widget.onOpenMore,
      ),
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: widget.onRefresh,
          child: ListView(
            key: const PageStorageKey('adult-home'),
            padding: const EdgeInsets.fromLTRB(22, 28, 22, 24),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Semantics(
                          header: true,
                          child: Text(
                            text.homeToday,
                            style: const TextStyle(
                              fontFamily: 'DMSerifDisplay',
                              fontSize: 34,
                              color: TataColors.ink,
                            ),
                          ),
                        ),
                        Text(
                          '${date[0].toUpperCase()}${date.substring(1)}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: TataColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  InitialsAvatar(name: widget.adultName),
                ],
              ),
              const SizedBox(height: 20),
              if (_syncNotice(text) case final notice?) ...[
                Semantics(
                  liveRegion: true,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: TataColors.infoSurface,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      notice,
                      style: const TextStyle(
                        fontSize: 14,
                        color: TataColors.infoText,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
              ],
              switch ((state.status, next)) {
                (HomeStatus.loading, _) => HomeMessageCard(
                  title: text.homeLoading,
                ),
                (HomeStatus.failure, _) => HomeMessageCard(
                  title: text.homeErrorTitle,
                  body: widget.errorText,
                  action: text.homeRetry,
                  onAction: widget.onRefresh,
                ),
                (HomeStatus.ready, null) => HomeMessageCard(
                  title: text.homeEmptyTitle,
                  body: text.homeEmptyDescription,
                ),
                (HomeStatus.ready, final Intake intake) => NextIntakeCard(
                  intake: intake,
                  now: now,
                  onTap: switch (widget.onOpenDose) {
                    final open? => () => open(intake.id),
                    null => null,
                  },
                ),
              },
              const SizedBox(height: 18),
              DailyProgressCard(
                progress: state.status == HomeStatus.ready
                    ? state.progress
                    : null,
                onOpen: widget.onOpenAgenda,
              ),
              if (_shortcuts(text, next?.id) case final shortcuts?) ...[
                const SizedBox(height: 18),
                shortcuts,
              ],
              if (_showTip) ...[
                const SizedBox(height: 18),
                DailyTipCard(onDismiss: () => setState(() => _showTip = false)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String? _syncNotice(AppLocalizations text) {
    final status = widget.syncStatus;
    if (status == null) return null;
    final queued = status.queued > 0
        ? text.homeQueuedBanner(status.queued)
        : null;
    return status.offline
        ? [text.homeOfflineBanner, ?queued].join(' ')
        : queued;
  }

  Widget? _shortcuts(AppLocalizations text, String? nextId) {
    final voice = widget.onOpenVoice;
    final agenda = widget.onOpenAgenda;
    final tiles = [
      Tooltip(
        message: voice == null
            ? text.homeVoiceUnavailable
            : text.homeVoiceSubtitle,
        child: HomeShortcut(
          title: text.homeVoiceTitle,
          subtitle: text.homeVoiceSubtitle,
          icon: 'assets/icons/home_mic.svg',
          color: TataColors.mint,
          onTap: voice != null && nextId != null ? () => voice(nextId) : null,
        ),
      ),
      if (agenda != null)
        HomeShortcut(
          title: text.homeAgendaTitle,
          subtitle: text.homeAgendaSubtitle,
          icon: 'assets/icons/home_list.svg',
          color: const Color(0xFFE1EFF8),
          onTap: agenda,
        ),
    ];
    if (tiles.isEmpty) return null;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var index = 0; index < tiles.length; index++) ...[
            if (index > 0) const SizedBox(width: 11),
            Expanded(child: tiles[index]),
          ],
        ],
      ),
    );
  }
}
