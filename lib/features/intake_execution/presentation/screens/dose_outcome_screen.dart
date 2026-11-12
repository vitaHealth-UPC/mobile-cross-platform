import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/presentation/theme/tata_colors.dart';
import '../../../../shared/presentation/widgets/adult_navigation_bar.dart';
import '../../domain/entities/intake.dart';
import '../bloc/dose/dose_state.dart';
import '../widgets/intake_labels.dart';

/// Figma 563:291 (confirmed), 563:3770 (late), 563:2760 (already confirmed)
/// and 563:3844 (omission preserved). The text never claims more than the
/// server receipt proves, for example that the family was notified.
class DoseOutcomeScreen extends StatelessWidget {
  const DoseOutcomeScreen({
    super.key,
    required this.outcome,
    required this.intake,
    required this.now,
    required this.onBackHome,
    this.next,
    this.onMore,
    this.onMedications,
    this.onAgenda,
  });

  final ConfirmationOutcome outcome;
  final Intake intake;
  final Intake? next;
  final VoidCallback? onMore;
  final VoidCallback? onMedications;
  final VoidCallback? onAgenda;
  final DateTime now;
  final VoidCallback onBackHome;

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    final omitted = outcome == ConfirmationOutcome.omissionPreserved;
    final queued = outcome == ConfirmationOutcome.pendingSync;
    final (title, subtitle) = switch (outcome) {
      ConfirmationOutcome.confirmed => (
        text.outcomeWellDone,
        text.outcomeConfirmed,
      ),
      ConfirmationOutcome.late => (
        text.outcomeWellDone,
        text.outcomeLateSubtitle,
      ),
      ConfirmationOutcome.alreadyConfirmed => (
        text.outcomeWellDone,
        text.outcomeAlreadyTitle,
      ),
      ConfirmationOutcome.omissionPreserved => (
        text.outcomeOmittedTitle,
        text.outcomeOmittedBody,
      ),
      ConfirmationOutcome.pendingSync => (
        text.outcomeQueuedTitle,
        text.outcomeQueuedBody,
      ),
    };
    // The recorded instant is the evidence; an omission has none, so show the schedule.
    final recorded = intake.confirmedAt ?? intake.scheduledAt;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) onBackHome();
      },
      child: Scaffold(
        bottomNavigationBar: AdultNavigationBar(
          selected: AdultDestination.home,
          onHome: onBackHome,
          onAgenda: onAgenda,
          onMore: onMore,
          onMedications: onMedications,
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(22, 40, 22, 24),
            children: [
              SizedBox(
                height: 150,
                child: ExcludeSemantics(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (!omitted && !queued)
                        Positioned(
                          top: 0,
                          child: Image.asset(
                            'assets/illustrations/dose_confetti.png',
                            width: 150,
                            height: 60,
                          ),
                        ),
                      if (omitted)
                        Container(
                          width: 96,
                          height: 96,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFFFFDF96),
                          ),
                          child: const Icon(
                            Icons.priority_high,
                            size: 52,
                            color: Color(0xFF916119),
                          ),
                        )
                      else if (queued)
                        Container(
                          width: 96,
                          height: 96,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: TataColors.primary,
                          ),
                          child: const Icon(
                            Icons.cloud_upload_outlined,
                            size: 52,
                            color: Colors.white,
                          ),
                        )
                      else
                        SvgPicture.asset('assets/icons/dose_success.svg'),
                      if (!omitted && !queued)
                        const Icon(Icons.check, size: 52, color: Colors.white),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Semantics(
                header: true,
                liveRegion: true,
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'DMSerifDisplay',
                    fontSize: 30,
                    color: TataColors.ink,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: TataColors.primary,
                ),
              ),
              const SizedBox(height: 26),
              _Card(
                color: Colors.white,
                child: Row(
                  children: [
                    SvgPicture.asset('assets/icons/dose_calendar.svg'),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${intakeDay(context, recorded, now)} · '
                            '${intake.medicationName}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: TataColors.muted,
                            ),
                          ),
                          Text(
                            intakeTime(context, recorded),
                            style: const TextStyle(
                              fontSize: 27,
                              fontWeight: FontWeight.w700,
                              color: TataColors.ink,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (next case final upcoming?) ...[
                const SizedBox(height: 14),
                _Card(
                  color: TataColors.mint,
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
                                color: TataColors.muted,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              upcoming.medicationName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: TataColors.ink,
                              ),
                            ),
                            Text(
                              text.doseDayTime(
                                intakeDay(context, upcoming.scheduledAt, now),
                                intakeTime(context, upcoming.scheduledAt),
                              ),
                              style: const TextStyle(
                                fontSize: 14,
                                color: TataColors.ink,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ExcludeSemantics(
                        child: Image.asset(
                          'assets/illustrations/home_tablet.png',
                          width: 76,
                          height: 76,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              // Progress and history are only true once the server has it.
              if (!omitted && !queued) ...[
                const SizedBox(height: 14),
                _Card(
                  color: TataColors.lavender,
                  child: Row(
                    children: [
                      SvgPicture.asset('assets/icons/dose_family.svg'),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              text.outcomeProgressTitle,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: TataColors.ink,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              text.outcomeProgressBody,
                              style: const TextStyle(
                                fontSize: 13,
                                color: TataColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 28),
              ElevatedButton(
                onPressed: onBackHome,
                child: Text(text.outcomeBackHome),
              ),
              if (outcome != ConfirmationOutcome.confirmed && !queued) ...[
                const SizedBox(height: 18),
                _Card(
                  color: outcome == ConfirmationOutcome.alreadyConfirmed
                      ? TataColors.lavender
                      : const Color(0xFFFFF5DE),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        outcome == ConfirmationOutcome.alreadyConfirmed
                            ? text.outcomeReplayNoticeTitle
                            : omitted
                            ? text.outcomeOmittedTitle
                            : text.outcomeLateNoticeTitle,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        outcome == ConfirmationOutcome.alreadyConfirmed
                            ? text.outcomeAlreadyBody
                            : omitted
                            ? text.outcomeOmittedBody
                            : text.outcomeLateBody,
                        style: const TextStyle(
                          fontSize: 12,
                          color: TataColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.color, required this.child});
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(20),
      boxShadow: const [
        BoxShadow(
          color: Color(0x10173B70),
          blurRadius: 16,
          offset: Offset(0, 6),
        ),
      ],
    ),
    child: child,
  );
}
