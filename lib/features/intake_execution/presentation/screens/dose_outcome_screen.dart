import 'package:flutter/material.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/presentation/theme/tata_colors.dart';
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
  });

  final ConfirmationOutcome outcome;
  final Intake intake;
  final Intake? next;
  final DateTime now;
  final VoidCallback onBackHome;

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    final omitted = outcome == ConfirmationOutcome.omissionPreserved;
    final (title, subtitle) = switch (outcome) {
      ConfirmationOutcome.confirmed => (
        text.outcomeWellDone,
        text.outcomeConfirmed,
      ),
      ConfirmationOutcome.late => (text.outcomeLateTitle, text.outcomeLateBody),
      ConfirmationOutcome.alreadyConfirmed => (
        text.outcomeAlreadyTitle,
        text.outcomeAlreadyBody,
      ),
      ConfirmationOutcome.omissionPreserved => (
        text.outcomeOmittedTitle,
        text.outcomeOmittedBody,
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
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(22, 40, 22, 24),
            children: [
              Center(
                child: ExcludeSemantics(
                  child: Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: omitted
                          ? TataColors.errorSurface
                          : const Color(0xFF9BD3AE),
                    ),
                    child: Icon(
                      omitted ? Icons.history : Icons.check,
                      size: 52,
                      color: omitted ? TataColors.errorText : Colors.white,
                    ),
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
                    const Icon(
                      Icons.event_available_outlined,
                      color: TataColors.primary,
                    ),
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
                              fontSize: 26,
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
              ],
              if (!omitted) ...[
                const SizedBox(height: 14),
                _Card(
                  color: TataColors.lavender,
                  child: Row(
                    children: [
                      const Icon(
                        Icons.insights_outlined,
                        color: TataColors.primary,
                      ),
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
