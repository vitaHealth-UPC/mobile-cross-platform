import 'package:flutter/material.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/presentation/theme/tata_colors.dart';

/// Managed person context with actual medication count and a host-supplied global badge.
/// Initials represent the selected person when the profile contract has no photo.
class ManagedPersonCard extends StatelessWidget {
  const ManagedPersonCard({
    super.key,
    required this.name,
    this.activeMedicationCount,
    this.adherenceBadge,
  });
  final String name;
  final int? activeMedicationCount;
  final Widget? adherenceBadge;
  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    final parts = name.trim().split(RegExp(r'\s+'));
    final initials =
        (parts.first.characters.first +
                (parts.length > 1 ? parts.last.characters.first : ''))
            .toUpperCase();
    final large = MediaQuery.textScalerOf(context).scale(14) > 18;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x141A2138),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFFE9E3FA),
                foregroundColor: TataColors.primary,
                child: Text(
                  initials,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (activeMedicationCount != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        text.tmActiveMedicationCount(activeMedicationCount!),
                        style: const TextStyle(
                          fontSize: 10,
                          color: TataColors.muted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (!large && adherenceBadge != null) ...[
                const SizedBox(width: 8),
                adherenceBadge!,
              ],
            ],
          ),
          if (large && adherenceBadge != null) ...[
            const SizedBox(height: 8),
            Align(alignment: Alignment.centerRight, child: adherenceBadge!),
          ],
        ],
      ),
    );
  }
}
