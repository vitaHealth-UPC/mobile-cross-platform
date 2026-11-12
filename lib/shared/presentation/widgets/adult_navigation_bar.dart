import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../theme/tata_colors.dart';

/// Stable adult destinations from the prototype, independent of route ownership.
enum AdultDestination { home, medications, agenda, notes, more }

/// Shared adult bar. Unconnected destinations remain explicitly disabled;
/// selection never disappears when a nested screen opens.
class AdultNavigationBar extends StatelessWidget {
  const AdultNavigationBar({
    super.key,
    required this.selected,
    this.onHome,
    this.onMedications,
    this.onAgenda,
    this.onNotes,
    this.onMore,
  });

  final AdultDestination selected;
  final VoidCallback? onHome;
  final VoidCallback? onMedications;
  final VoidCallback? onAgenda;
  final VoidCallback? onNotes;
  final VoidCallback? onMore;

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    final items = [
      (AdultDestination.home, text.homeTabStart, 'home', onHome),
      (
        AdultDestination.medications,
        text.adultTabMedications,
        'medications',
        onMedications,
      ),
      (AdultDestination.agenda, text.homeTabAgenda, 'agenda', onAgenda),
      (AdultDestination.notes, text.adultTabNotes, 'notes', onNotes),
      (AdultDestination.more, text.homeTabMore, 'more', onMore),
    ];
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(14, 0, 14, 8),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: const Color(0xCCEDEFF4)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x141A2138),
              blurRadius: 18,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            for (final (destination, label, icon, onTap) in items)
              Expanded(
                child: Semantics(
                  button: true,
                  selected: selected == destination,
                  enabled: selected == destination || onTap != null,
                  label: label,
                  excludeSemantics: true,
                  child: InkWell(
                    onTap: onTap,
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 38,
                            height: 30,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: selected == destination
                                  ? TataColors.primary
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Transform.rotate(
                              angle: destination == AdultDestination.medications
                                  ? -42 * math.pi / 180
                                  : 0,
                              child: SvgPicture.asset(
                                'assets/icons/adult_tab_$icon.svg',
                                colorFilter: ColorFilter.mode(
                                  selected == destination
                                      ? Colors.white
                                      : TataColors.muted,
                                  BlendMode.srcIn,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 9,
                              color: selected == destination
                                  ? TataColors.primary
                                  : TataColors.muted,
                            ),
                          ),
                        ],
                      ),
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
