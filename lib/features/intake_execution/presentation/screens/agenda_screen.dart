import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/presentation/theme/tata_colors.dart';
import '../../../../shared/presentation/theme/tata_typography.dart';
import '../../domain/entities/intake.dart';
import '../bloc/agenda/agenda_state.dart';
import '../widgets/intake_labels.dart';

/// Figma 563:500 / 563:3918 weekly agenda with per-dose status (US-24).
class AgendaScreen extends StatelessWidget {
  const AgendaScreen({
    super.key,
    required this.state,
    required this.today,
    required this.onSelectDay,
    required this.onMoveWeek,
    required this.onRetry,
    required this.onOpenDose,
    this.errorText,
    this.onBack,
  });

  final AgendaState state;

  /// Local date used to mark the current day.
  final DateTime today;
  final ValueChanged<DateTime> onSelectDay;
  final ValueChanged<int> onMoveWeek;
  final Future<void> Function() onRetry;
  final ValueChanged<String> onOpenDose;
  final String? errorText;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final days = state.week.days;
    final range = text.agendaWeekRange(
      DateFormat.d(locale).format(days.first),
      DateFormat.MMMMd(locale).format(days.last),
    );
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: onRetry,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(22, 16, 22, 24),
            children: [
              Row(
                children: [
                  if (onBack != null)
                    IconButton(
                      onPressed: onBack,
                      tooltip: text.back,
                      icon: const Icon(Icons.chevron_left),
                    ),
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(
                        text.agendaTitle,
                        style: TataTypography.heading,
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      range,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: TataColors.primary,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => onMoveWeek(-1),
                    tooltip: text.agendaPreviousWeek,
                    icon: const Icon(Icons.chevron_left),
                  ),
                  IconButton(
                    onPressed: () => onMoveWeek(1),
                    tooltip: text.agendaNextWeek,
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  for (final day in days)
                    Expanded(
                      child: _DayCell(
                        day: day,
                        selected: _sameDay(day, state.selectedDay),
                        today: _sameDay(day, today),
                        onTap: () => onSelectDay(day),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              ..._body(context, text),
              const SizedBox(height: 16),
              _Tip(title: text.homeTipTitle, body: text.agendaTipBody),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _body(BuildContext context, AppLocalizations text) {
    switch (state.status) {
      case AgendaStatus.loading:
        return [
          Semantics(
            label: text.agendaLoading,
            child: const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            ),
          ),
        ];
      case AgendaStatus.failure:
        return [
          _Message(
            title: text.agendaErrorTitle,
            body: errorText,
            action: text.homeRetry,
            onAction: onRetry,
          ),
        ];
      case AgendaStatus.ready:
        final intakes = state.selectedIntakes;
        if (intakes.isEmpty) {
          return [
            _Message(title: text.agendaEmptyDay, body: text.agendaEmptyDayBody),
          ];
        }
        return [
          for (final intake in intakes)
            _AgendaEntry(intake: intake, onTap: () => onOpenDose(intake.id)),
        ];
    }
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.selected,
    required this.today,
    required this.onTap,
  });

  final DateTime day;
  final bool selected;
  final bool today;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final letter = DateFormat.EEEEE(locale).format(day).toUpperCase();
    return Semantics(
      button: true,
      selected: selected,
      label: DateFormat.MMMMEEEEd(locale).format(day),
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            children: [
              Text(
                letter,
                style: const TextStyle(fontSize: 12, color: TataColors.muted),
              ),
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? TataColors.primary : Colors.transparent,
                  shape: BoxShape.circle,
                  border: today && !selected
                      ? Border.all(color: TataColors.primary)
                      : null,
                ),
                child: Text(
                  '${day.day}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : TataColors.ink,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AgendaEntry extends StatelessWidget {
  const _AgendaEntry({required this.intake, required this.onTap});

  final Intake intake;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    final time = intakeTime(context, intake.scheduledAt);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Semantics(
        button: true,
        label: text.agendaDoseSemantics(
          time,
          intake.medicationName,
          intakeStatusLabel(text, intake.status),
        ),
        excludeSemantics: true,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 72,
              child: Padding(
                padding: const EdgeInsets.only(top: 14),
                child: Column(
                  children: [
                    Text(
                      time,
                      style: const TextStyle(
                        fontSize: 12,
                        color: TataColors.ink,
                      ),
                    ),
                    const SizedBox(height: 10),
                    IntakePeriodIcon(instant: intake.scheduledAt),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Material(
                color: intakeCardColor(intake.scheduledAt),
                borderRadius: BorderRadius.circular(18),
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: onTap,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                intake.medicationName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: TataColors.ink,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                intake.dose,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: TataColors.ink,
                                ),
                              ),
                              if (intake.instructions case final notes?
                                  when notes.trim().isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(
                                  notes,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: TataColors.muted,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        IntakeStatusMark(status: intake.status),
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

class _Message extends StatelessWidget {
  const _Message({required this.title, this.body, this.action, this.onAction});

  final String title;
  final String? body;
  final String? action;
  final Future<void> Function()? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: TataColors.softBorder),
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

class _Tip extends StatelessWidget {
  const _Tip({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F2FC),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.notifications_none, color: TataColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: TataColors.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
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
