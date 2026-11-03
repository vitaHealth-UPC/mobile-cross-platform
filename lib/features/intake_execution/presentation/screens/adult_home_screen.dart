import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/presentation/theme/tata_colors.dart';
import '../../../../shared/presentation/widgets/initials_avatar.dart';
import '../../domain/entities/intake.dart';
import '../bloc/home/home_state.dart';
import '../widgets/home_cards.dart';

/// Figma 563:58 adult home. Shortcuts appear only when their flow exists.
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
  });

  final HomeState state;
  final String? adultName;
  final DateTime Function() clock;
  final Future<void> Function() onRefresh;

  /// Opens account actions such as consent management and switching account.
  final VoidCallback onOpenMore;
  final String? errorText;
  final ValueChanged<String>? onOpenVoice;
  final VoidCallback? onOpenAgenda;

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
      bottomNavigationBar: _AdultTabBar(
        homeLabel: text.homeTabStart,
        moreLabel: text.homeTabMore,
        onMore: widget.onOpenMore,
      ),
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: widget.onRefresh,
          child: ListView(
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

  Widget? _shortcuts(AppLocalizations text, String? nextId) {
    final voice = widget.onOpenVoice;
    final agenda = widget.onOpenAgenda;
    final tiles = [
      if (voice != null && nextId != null)
        HomeShortcut(
          title: text.homeVoiceTitle,
          subtitle: text.homeVoiceSubtitle,
          icon: 'assets/icons/home_mic.svg',
          color: TataColors.mint,
          onTap: () => voice(nextId),
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

/// Adult navigation from Figma 563:58, limited to destinations that exist.
class _AdultTabBar extends StatelessWidget {
  const _AdultTabBar({
    required this.homeLabel,
    required this.moreLabel,
    required this.onMore,
  });

  final String homeLabel;
  final String moreLabel;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(14, 0, 14, 8),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14173B70),
              blurRadius: 16,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: _TabItem(
                label: homeLabel,
                icon: 'assets/icons/adult_tab_home.svg',
                selected: true,
              ),
            ),
            Expanded(
              child: _TabItem(
                label: moreLabel,
                icon: 'assets/icons/adult_tab_more.svg',
                selected: false,
                onTap: onMore,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.label,
    required this.icon,
    required this.selected,
    this.onTap,
  });

  final String label;
  final String icon;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 38,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? TataColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(15),
              ),
              child: SvgPicture.asset(
                icon,
                width: 22,
                height: 22,
                colorFilter: ColorFilter.mode(
                  selected ? Colors.white : TataColors.muted,
                  BlendMode.srcIn,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: selected ? TataColors.primary : TataColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
