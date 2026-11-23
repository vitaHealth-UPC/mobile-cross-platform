import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../theme/tata_colors.dart';

/// Sections of the caregiver bottom bar, in the order Figma draws them.
enum CaregiverTab {
  /// Family summary.
  home('assets/icons/caregiver_tab_home.svg'),

  /// Open alerts.
  alerts('assets/icons/caregiver_tab_alerts.svg'),

  /// Follow-up notes.
  notes('assets/icons/caregiver_tab_notes.svg'),

  /// Person under care.
  person('assets/icons/caregiver_tab_person.svg'),

  /// Secondary options.
  more('assets/icons/caregiver_tab_more.svg');

  const CaregiverTab(this.icon);

  /// Original Figma icon of the tab.
  final String icon;
}

/// Bottom navigation of the caregiver app ("System / Tab Bar" in Figma).
///
/// Presentation only: the owner of each flow decides where a tab leads and
/// which one is [selected]. The bar is never a source of truth for navigation.
class CaregiverTabBar extends StatelessWidget {
  const CaregiverTabBar({
    super.key,
    required this.selected,
    required this.onSelected,
    this.enabledTabs = const {
      CaregiverTab.home,
      CaregiverTab.alerts,
      CaregiverTab.notes,
      CaregiverTab.person,
      CaregiverTab.more,
    },
  });

  final CaregiverTab selected;
  final ValueChanged<CaregiverTab> onSelected;

  /// Unconnected destinations expose no tap action.
  final Set<CaregiverTab> enabledTabs;

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    final labels = {
      CaregiverTab.home: text.caregiverTabHome,
      CaregiverTab.alerts: text.caregiverTabAlerts,
      CaregiverTab.notes: text.caregiverTabNotes,
      CaregiverTab.person: text.caregiverTabPerson,
      CaregiverTab.more: text.caregiverTabMore,
    };
    return Semantics(
      container: true,
      label: text.caregiverTabBarSemantics,
      child: Container(
        height: 68,
        // Figma keeps the bar 16 px above the frame bottom, over the home
        // indicator area; on gesture navigation the system inset is used when
        // it is larger, so the bar is never covered.
        margin: EdgeInsets.fromLTRB(
          14,
          0,
          14,
          math.max(16, MediaQuery.paddingOf(context).bottom),
        ),
        decoration: BoxDecoration(
          color: const Color(0xF7FFFFFF),
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
            for (final tab in CaregiverTab.values)
              Expanded(
                child: _TabItem(
                  tab: tab,
                  label: labels[tab]!,
                  active: tab == selected,
                  onTap: enabledTabs.contains(tab)
                      ? () => onSelected(tab)
                      : null,
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
    required this.tab,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final CaregiverTab tab;
  final String label;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    enabled: onTap != null,
    selected: active,
    label: label,
    // The inner ink well is excluded, so the tap action is declared here.
    onTap: onTap,
    excludeSemantics: true,
    child: InkWell(
      borderRadius: BorderRadius.circular(28),
      onTap: onTap,
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 38,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: active ? TataColors.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(15),
            ),
            child: SvgPicture.asset(
              tab.icon,
              width: 22,
              height: 22,
              colorFilter: ColorFilter.mode(
                active ? Colors.white : TataColors.muted,
                BlendMode.srcIn,
              ),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 8.5,
              height: 12 / 8.5,
              fontWeight: active ? FontWeight.w600 : FontWeight.w400,
              color: active ? TataColors.primary : TataColors.muted,
            ),
          ),
        ],
      ),
    ),
  );
}
