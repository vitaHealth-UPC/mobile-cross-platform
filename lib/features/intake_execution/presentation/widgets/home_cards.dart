import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/presentation/theme/tata_colors.dart';
import '../../application/readmodels/daily_progress.dart';
import '../../domain/entities/intake.dart';

const _cardShadow = [
  BoxShadow(color: Color(0x12173B70), blurRadius: 16, offset: Offset(0, 6)),
];

/// Figma 563:58 next-dose card: local time, medication, dose and time remaining.
class NextIntakeCard extends StatelessWidget {
  const NextIntakeCard({
    super.key,
    required this.intake,
    required this.now,
    this.onTap,
  });

  final Intake intake;
  final DateTime now;

  /// Opens the dose detail, where the dose can be confirmed.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    // Figma uses a 12-hour clock ("8:00 a. m."), which the es skeleton would not.
    final time = DateFormat(
      'h:mm a',
      locale,
    ).format(intake.scheduledAt.toLocal());
    final card = Ink(
      padding: const EdgeInsets.fromLTRB(18, 18, 8, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFFEEE8FF), Color(0xFFE5DDF8)],
        ),
        boxShadow: _cardShadow,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text.homeNextDose,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: TataColors.primary,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  time,
                  style: const TextStyle(
                    fontSize: 31,
                    fontWeight: FontWeight.w700,
                    color: TataColors.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  intake.medicationName,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: TataColors.ink,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  intake.dose,
                  style: const TextStyle(fontSize: 13, color: TataColors.muted),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _remaining(text),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF5961B2),
                    ),
                  ),
                ),
              ],
            ),
          ),
          ExcludeSemantics(
            child: Image.asset(
              'assets/illustrations/home_tablet.png',
              width: 120,
              height: 120,
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: card,
      ),
    );
  }

  String _remaining(AppLocalizations text) {
    final minutes = (intake.scheduledAt.difference(now).inSeconds / 60).ceil();
    if (minutes <= 0) return text.homeDueNow;
    if (minutes < 60) return text.homeInMinutes(minutes);
    return text.homeInHours(minutes ~/ 60);
  }
}

/// Plain card for loading, empty and error states of the next intake.
class HomeMessageCard extends StatelessWidget {
  const HomeMessageCard({
    super.key,
    required this.title,
    this.body,
    this.action,
    this.onAction,
  });

  final String title;
  final String? body;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: _cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: TataColors.ink,
            ),
          ),
          if (body case final message?) ...[
            const SizedBox(height: 6),
            Text(
              message,
              style: const TextStyle(fontSize: 13, color: TataColors.muted),
            ),
          ],
          if ((action, onAction) case (final label?, final retry?)) ...[
            const SizedBox(height: 12),
            ElevatedButton(onPressed: retry, child: Text(label)),
          ],
        ],
      ),
    );
  }
}

/// Figma 563:58 progress card; null progress means today's agenda is unavailable.
class DailyProgressCard extends StatelessWidget {
  const DailyProgressCard({super.key, required this.progress, this.onOpen});

  final DailyProgress? progress;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    final value = progress;
    final message = switch (value) {
      null => text.homeProgressUnavailable,
      DailyProgress(total: 0) => text.homeProgressEmpty,
      DailyProgress(:final taken, :final total) when taken == total =>
        text.homeProgressDone,
      DailyProgress(taken: > 0) => text.homeProgressInProgress,
      _ => text.homeProgressEncouragement,
    };
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      shadowColor: const Color(0x33173B70),
      elevation: 3,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                text.homeProgressTitle,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: TataColors.ink,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  SizedBox.square(
                    dimension: 48,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Positioned.fill(
                          child: CircularProgressIndicator(
                            value: value?.ratio ?? 0,
                            strokeWidth: 5,
                            color: const Color(0xFF7D6BE5),
                            backgroundColor: TataColors.lavender,
                          ),
                        ),
                        Text(
                          value == null
                              ? '—'
                              : text.homeProgressValue(
                                  value.taken,
                                  value.total,
                                ),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: TataColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          text.homeCompleted,
                          style: const TextStyle(
                            fontSize: 14,
                            color: TataColors.muted,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          message,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: TataColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (onOpen != null)
                    const Icon(Icons.chevron_right, color: TataColors.primary),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Figma 563:58 shortcut tile for voice confirmation or the full agenda.
class HomeShortcut extends StatelessWidget {
  const HomeShortcut({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(18),
      shadowColor: const Color(0x33173B70),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 19,
                        height: 1.2,
                        fontWeight: FontWeight.w700,
                        color: TataColors.ink,
                      ),
                    ),
                  ),
                  SvgPicture.asset(icon, width: 28, height: 28),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 12, color: TataColors.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dismissible daily tip from Figma 563:58.
class DailyTipCard extends StatelessWidget {
  const DailyTipCard({super.key, required this.onDismiss});

  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 6, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF4E2), Color(0xFFFBE9CD)],
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.wb_sunny_outlined, color: Color(0xFFC48C29)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text.homeTipTitle,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFC48C29),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  text.homeTipDescription,
                  style: const TextStyle(fontSize: 14, color: TataColors.ink),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onDismiss,
            tooltip: text.homeDismissTip,
            icon: const Icon(Icons.close, size: 18, color: TataColors.muted),
          ),
        ],
      ),
    );
  }
}
