import 'package:flutter/material.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/presentation/theme/tata_colors.dart';
import '../../domain/entities/intake.dart';
import '../widgets/intake_labels.dart';

/// Figma 563:3266 (pending), 563:3370 (confirmed), 563:3474 (late) and
/// 563:3578 (omitted). Only clinical data from the server is shown; rows the
/// backend does not provide, such as the treatment purpose, are not invented.
class DoseDetailScreen extends StatelessWidget {
  const DoseDetailScreen({
    super.key,
    required this.intake,
    required this.now,
    required this.confirming,
    required this.canConfirm,
    required this.onConfirm,
    required this.onBack,
    this.errorText,
  });

  final Intake intake;
  final DateTime now;
  final bool confirming;
  final bool canConfirm;
  final VoidCallback onConfirm;
  final VoidCallback onBack;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    final time = intakeTime(context, intake.scheduledAt);
    final day = intakeDay(context, intake.scheduledAt, now);
    final pending = intake.status == IntakeStatus.pending;
    return PopScope(
      canPop: !confirming,
      child: Scaffold(
        // The main action stays visible above the system bar on any screen height.
        bottomNavigationBar: pending
            ? SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(22, 8, 22, 12),
                  child: ElevatedButton(
                    onPressed: canConfirm ? onConfirm : null,
                    child: Text(
                      confirming ? text.doseConfirming : text.doseConfirm,
                    ),
                  ),
                ),
              )
            : null,
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(14, 12, 22, 24),
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: confirming ? null : onBack,
                    tooltip: text.back,
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(
                        text.doseTitle,
                        style: const TextStyle(
                          fontFamily: 'DMSerifDisplay',
                          fontSize: 26,
                          color: TataColors.ink,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Hero(intake: intake),
                    const SizedBox(height: 22),
                    _SectionLabel(text.doseScheduleLabel),
                    const SizedBox(height: 8),
                    _ScheduleCard(intake: intake, day: day, time: time),
                    const SizedBox(height: 22),
                    _SectionLabel(text.doseInformation),
                    const SizedBox(height: 8),
                    _InfoCard(
                      rows: [
                        (
                          Icons.medication_outlined,
                          text.doseDoseLabel,
                          intake.dose,
                        ),
                        (
                          Icons.schedule,
                          text.doseWhenLabel,
                          text.doseDayTime(day, time),
                        ),
                        (
                          Icons.description_outlined,
                          text.doseInstructionsLabel,
                          switch (intake.instructions) {
                            final notes? when notes.trim().isNotEmpty => notes,
                            _ => text.doseNoInstructions,
                          },
                        ),
                      ],
                    ),
                    if (pending) ...[
                      const SizedBox(height: 22),
                      _BeforeDose(
                        title: text.doseBeforeTitle,
                        items: [
                          text.dosePrepareMedication,
                          text.dosePrepareWater,
                          text.dosePrepareSeat,
                        ],
                      ),
                    ],
                    const SizedBox(height: 16),
                    _StatusNote(intake: intake),
                    if (errorText case final message?) ...[
                      const SizedBox(height: 12),
                      Semantics(
                        liveRegion: true,
                        child: Text(
                          message,
                          style: const TextStyle(color: TataColors.errorText),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.intake});
  final Intake intake;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 14, 18, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFFEEE8FF), Color(0xFFE5DDF8)],
        ),
      ),
      child: Row(
        children: [
          ExcludeSemantics(
            child: Image.asset(
              'assets/illustrations/home_tablet.png',
              width: 96,
              height: 96,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  intake.medicationName,
                  style: const TextStyle(
                    fontFamily: 'DMSerifDisplay',
                    fontSize: 24,
                    color: TataColors.ink,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  intake.dose,
                  style: const TextStyle(fontSize: 14, color: TataColors.ink),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Text(
    label,
    style: const TextStyle(fontSize: 13, color: TataColors.muted),
  );
}

class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard({
    required this.intake,
    required this.day,
    required this.time,
  });

  final Intake intake;
  final String day;
  final String time;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: TataColors.softBorder),
      ),
      child: Row(
        children: [
          IntakePeriodIcon(instant: intake.scheduledAt, size: 26),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  day,
                  style: const TextStyle(fontSize: 13, color: TataColors.muted),
                ),
                Text(
                  time,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: TataColors.ink,
                  ),
                ),
              ],
            ),
          ),
          IntakeStatusChip(status: intake.status),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.rows});
  final List<(IconData, String, String)> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: TataColors.softBorder),
      ),
      child: Column(
        children: [
          for (final (icon, label, value) in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, size: 20, color: TataColors.primary),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 96,
                    child: Text(
                      label,
                      style: const TextStyle(
                        fontSize: 14,
                        color: TataColors.muted,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      value,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: TataColors.ink,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _BeforeDose extends StatelessWidget {
  const _BeforeDose({required this.title, required this.items});
  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TataColors.lavender,
        borderRadius: BorderRadius.circular(18),
      ),
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
          const SizedBox(height: 10),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  const Icon(Icons.check, size: 18, color: TataColors.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(
                        fontSize: 14,
                        color: TataColors.ink,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _StatusNote extends StatelessWidget {
  const _StatusNote({required this.intake});
  final Intake intake;

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    final message = switch (intake.status) {
      IntakeStatus.pending => text.doseMessagePending,
      IntakeStatus.confirmed => text.doseMessageConfirmed,
      IntakeStatus.late => text.doseMessageLate,
      IntakeStatus.omitted => text.doseMessageOmitted,
    };
    final omitted = intake.status == IntakeStatus.omitted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: omitted ? TataColors.errorSurface : TataColors.infoSurface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            text.doseState(intakeStatusLabel(text, intake.status)),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: omitted ? TataColors.errorText : TataColors.infoText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            style: const TextStyle(fontSize: 13, color: TataColors.muted),
          ),
        ],
      ),
    );
  }
}
