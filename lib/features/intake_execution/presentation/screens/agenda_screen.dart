import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/presentation/theme/tata_colors.dart';
import '../../../../shared/presentation/theme/tata_typography.dart';
import '../../../../shared/presentation/widgets/adult_navigation_bar.dart';
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
    required this.onRetry,
    required this.onOpenDose,
    this.errorText,
    this.onBack,
    this.onMore,
    this.onMedications,
    this.onNotes,
  });

  final AgendaState state;

  /// Local date used to mark the current day.
  final DateTime today;
  final ValueChanged<DateTime> onSelectDay;
  final Future<void> Function() onRetry;
  final ValueChanged<String> onOpenDose;
  final String? errorText;
  final VoidCallback? onBack;
  final VoidCallback? onMore;
  final VoidCallback? onMedications;
  final VoidCallback? onNotes;

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final days = state.week.days;
    final includeYear =
        days.first.year != today.year || days.last.year != today.year;
    final fromFormat = includeYear
        ? DateFormat.yMMMd(locale)
        : days.first.month == days.last.month
        ? DateFormat.d(locale)
        : DateFormat.MMMMd(locale);
    final toFormat = includeYear
        ? DateFormat.yMMMd(locale)
        : DateFormat.MMMMd(locale);
    final range = text.agendaWeekRange(
      fromFormat.format(days.first),
      toFormat.format(days.last),
    );
    return Scaffold(
      bottomNavigationBar: AdultNavigationBar(
        selected: AdultDestination.agenda,
        onHome: onBack,
        onMore: onMore,
        onMedications: onMedications,
        onNotes: onNotes,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: onRetry,
          child: ListView(
            key: const PageStorageKey('adult-agenda'),
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 28, 22, 24),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Semantics(
                          header: true,
                          child: Text(
                            text.agendaTitle,
                            style: TataTypography.heading.copyWith(
                              fontSize: 29,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          range,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: TataColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  DecoratedBox(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x141A2138),
                          blurRadius: 18,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: IconButton(
                      tooltip: text.agendaChooseDate,
                      onPressed: () => _chooseDate(context),
                      icon: SvgPicture.asset(
                        'assets/icons/agenda_calendar.svg',
                        width: 22,
                        height: 22,
                        excludeFromSemantics: true,
                      ),
                    ),
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
              Padding(
                padding: const EdgeInsets.only(left: 74),
                child: _Tip(title: text.homeTipTitle, body: text.agendaTipBody),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _chooseDate(BuildContext context) async {
    final selected = await showDatePicker(
      context: context,
      initialDate: state.selectedDay,
      currentDate: today,
      firstDate: DateTime(1),
      lastDate: DateTime(9999, 12, 31),
      helpText: AppLocalizations.of(context).agendaChooseDate,
    );
    if (selected != null && context.mounted) onSelectDay(selected);
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
                style: const TextStyle(fontSize: 10, color: Color(0xFF5B6475)),
              ),
              const SizedBox(height: 8),
              Container(
                width: 36,
                height: 36,
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
                    fontSize: 12,
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
    final hour = intake.scheduledAt.toLocal().hour;
    final periodAsset = hour >= 18 || hour < 5
        ? 'agenda_night'
        : 'agenda_morning';
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Semantics(
        button: true,
        label: text.agendaDoseSemantics(
          time,
          intake.medicationName,
          intakeDisplayLabel(text, intake),
        ),
        excludeSemantics: true,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            const Positioned(
              left: 54,
              top: 0,
              bottom: -24,
              child: SizedBox(
                width: 2,
                child: ColoredBox(color: Color(0xFFE1E2ED)),
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 74,
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
                        Transform.translate(
                          offset: const Offset(17, 0),
                          child: ColoredBox(
                            color: TataColors.background,
                            child: SvgPicture.asset(
                              'assets/icons/$periodAsset.svg',
                              width: 22,
                              height: 22,
                              excludeFromSemantics: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Material(
                    color: _colors.first,
                    elevation: 2,
                    shadowColor: const Color(0x181A2138),
                    borderRadius: BorderRadius.circular(18),
                    child: Ink(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: _colors),
                        borderRadius: BorderRadius.circular(16),
                      ),
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
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: TataColors.ink,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      intake.dose,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: TataColors.ink,
                                      ),
                                    ),
                                    if (intake.instructions case final notes?
                                        when notes.trim().isNotEmpty) ...[
                                      const SizedBox(height: 6),
                                      Text(
                                        notes,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: TataColors.ink,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              IntakeStatusMark(
                                status: intake.status,
                                queued: intake.queued,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Color> get _colors {
    final hour = intake.scheduledAt.toLocal().hour;
    if (hour >= 21 || hour < 5) {
      return const [Color(0xFFEEF6FC), Color(0xFFE2EEF9)];
    }
    if (hour >= 12 && hour < 18) {
      return const [Color(0xFFFFF5E3), Color(0xFFFBE9C7)];
    }
    return const [Color(0xFFF1ECFF), Color(0xFFE7DFFC)];
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
        gradient: const LinearGradient(
          colors: [Color(0xFFEEF6FC), Color(0xFFE2EEF9)],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SvgPicture.asset(
            'assets/icons/agenda_tip.svg',
            width: 22,
            height: 22,
            excludeFromSemantics: true,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: TataColors.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: const TextStyle(fontSize: 12, color: TataColors.ink),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
