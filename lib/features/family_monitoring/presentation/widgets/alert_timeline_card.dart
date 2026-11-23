import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../shared/presentation/theme/tata_colors.dart';

/// Native card for a recorded alert or dose, preserving the event's own action.
/// The caller supplies localized labels; this widget does not classify outcomes.
class AlertTimelineCard extends StatelessWidget {
  const AlertTimelineCard({
    super.key,
    required this.title,
    required this.personAndTime,
    required this.medicationName,
    required this.asset,
    required this.colors,
    this.caption,
    this.badge,
    this.attentionBadge = false,
    this.onTap,
  });
  final String title;
  final String personAndTime;
  final String medicationName;
  final String asset;
  final List<Color> colors;
  final String? caption;
  final String? badge;
  final bool attentionBadge;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(18),
      boxShadow: const [
        BoxShadow(
          color: Color(0x141A2138),
          blurRadius: 18,
          offset: Offset(0, 6),
        ),
      ],
    ),
    child: Material(
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: Ink(
        decoration: BoxDecoration(gradient: LinearGradient(colors: colors)),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox.square(
                  dimension: 42,
                  child: Center(
                    child: SvgPicture.asset(
                      'assets/icons/$asset.svg',
                      width: 24,
                      height: 24,
                      excludeFromSemantics: true,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: TataColors.ink,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            personAndTime,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF5B6475),
                            ),
                          ),
                          if (badge case final value?)
                            DecoratedBox(
                              decoration: BoxDecoration(
                                color: attentionBadge
                                    ? const Color(0xFFFFE3D8)
                                    : const Color(0xFFECF7EE),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                child: Text(
                                  value,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: attentionBadge
                                        ? const Color(0xFF8A2E20)
                                        : const Color(0xFF3C7350),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        medicationName,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: TataColors.ink,
                        ),
                      ),
                      if (caption case final value?) ...[
                        const SizedBox(height: 4),
                        Text(
                          value,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF5B6475),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (onTap != null)
                  const Padding(
                    padding: EdgeInsets.only(top: 24),
                    child: Icon(
                      Icons.chevron_right,
                      size: 20,
                      color: TataColors.primary,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

/// Follow-up status supported by the loaded data, without inferring severity.
class AlertsStatusBanner extends StatelessWidget {
  const AlertsStatusBanner({
    super.key,
    required this.requiresAttention,
    required this.title,
    required this.body,
  });
  final bool requiresAttention;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: requiresAttention
            ? const [Color(0xFFFFF0E8), Color(0xFFFBE0D1)]
            : const [Color(0xFFECF8EF), Color(0xFFDDEFE2)],
      ),
      borderRadius: BorderRadius.circular(18),
    ),
    child: Row(
      children: [
        SizedBox.square(
          dimension: 46,
          child: Center(
            child: SvgPicture.asset(
              'assets/icons/${requiresAttention ? 'alerts_warning' : 'alerts_clear'}.svg',
              width: requiresAttention ? 24 : 22,
              height: requiresAttention ? 24 : 22,
              excludeFromSemantics: true,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: TataColors.ink,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                body,
                style: const TextStyle(fontSize: 12, color: Color(0xFF5B6475)),
              ),
            ],
          ),
        ),
        if (!requiresAttention)
          Image.asset(
            'assets/illustrations/alerts_botanical.png',
            width: 58,
            height: 72,
            excludeFromSemantics: true,
          ),
      ],
    ),
  );
}
