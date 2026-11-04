import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/presentation/theme/tata_colors.dart';
import '../../domain/entities/intake.dart';

/// Localized label of a server status.
String intakeStatusLabel(AppLocalizations text, IntakeStatus status) =>
    switch (status) {
      IntakeStatus.pending => text.intakeStatusPending,
      IntakeStatus.confirmed => text.intakeStatusConfirmed,
      IntakeStatus.late => text.intakeStatusLate,
      IntakeStatus.omitted => text.intakeStatusOmitted,
    };

/// 12-hour local time as drawn in Figma ("8:00 a. m.").
String intakeTime(BuildContext context, DateTime instant) => DateFormat(
  'h:mm a',
  Localizations.localeOf(context).toLanguageTag(),
).format(instant.toLocal());

/// "Hoy", "Mañana", "Ayer" or a calendar date, relative to [now].
String intakeDay(BuildContext context, DateTime instant, DateTime now) {
  final text = AppLocalizations.of(context);
  final local = instant.toLocal();
  final day = DateTime(local.year, local.month, local.day);
  final today = DateTime(now.year, now.month, now.day);
  if (day == today) return text.doseToday;
  if (day == DateTime(today.year, today.month, today.day + 1)) {
    return text.doseTomorrow;
  }
  if (day == DateTime(today.year, today.month, today.day - 1)) {
    return text.doseYesterday;
  }
  final label = DateFormat.MMMMEEEEd(
    Localizations.localeOf(context).toLanguageTag(),
  ).format(local);
  return '${label[0].toUpperCase()}${label.substring(1)}';
}

/// Morning and afternoon doses use the sun, evening doses the moon (Figma 563:3918).
class IntakePeriodIcon extends StatelessWidget {
  const IntakePeriodIcon({super.key, required this.instant, this.size = 22});

  final DateTime instant;
  final double size;

  @override
  Widget build(BuildContext context) {
    final night = instant.toLocal().hour >= 18 || instant.toLocal().hour < 5;
    return ExcludeSemantics(
      child: Icon(
        night ? Icons.nightlight_outlined : Icons.wb_sunny_outlined,
        size: size,
        color: night ? const Color(0xFF7D6BE5) : const Color(0xFFC48C29),
      ),
    );
  }
}

/// Card tint by time of day, so the agenda reads like the Figma timeline.
Color intakeCardColor(DateTime instant) {
  final hour = instant.toLocal().hour;
  if (hour >= 18 || hour < 5) return const Color(0xFFE9E3FB);
  if (hour >= 12) return const Color(0xFFFCEFD9);
  return const Color(0xFFEEE8FF);
}

/// Round status mark at the end of an agenda card.
class IntakeStatusMark extends StatelessWidget {
  const IntakeStatusMark({super.key, required this.status});

  final IntakeStatus status;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (status) {
      IntakeStatus.pending => (null, TataColors.muted),
      IntakeStatus.confirmed => (Icons.check, const Color(0xFF3E8E5E)),
      IntakeStatus.late => (Icons.schedule, const Color(0xFFC48C29)),
      IntakeStatus.omitted => (Icons.close, TataColors.errorText),
    };
    return ExcludeSemantics(
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: TataColors.softBorder),
        ),
        child: icon == null ? null : Icon(icon, size: 18, color: color),
      ),
    );
  }
}

/// Small rounded label with the server status.
class IntakeStatusChip extends StatelessWidget {
  const IntakeStatusChip({super.key, required this.status});

  final IntakeStatus status;

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    final (background, foreground) = switch (status) {
      IntakeStatus.pending => (
        const Color(0xFFFCEFD9),
        const Color(0xFFB0772A),
      ),
      IntakeStatus.confirmed => (TataColors.mint, const Color(0xFF2F7A4D)),
      IntakeStatus.late => (const Color(0xFFFFF4E2), const Color(0xFFB0772A)),
      IntakeStatus.omitted => (TataColors.errorSurface, TataColors.errorText),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        intakeStatusLabel(text, status),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: foreground,
        ),
      ),
    );
  }
}
