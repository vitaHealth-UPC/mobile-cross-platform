import 'package:flutter/material.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/value_objects/administration_schedule.dart';
import '../../domain/value_objects/regimen_text.dart';
import 'treatment_visuals.dart';

String frequencyLabel(AppLocalizations text, String raw) {
  final frequency = Frequency.tryParse(raw);
  return switch (frequency?.kind) {
    FrequencyKind.daily => text.tmFrequencyEveryDay,
    FrequencyKind.onceDaily => text.tmFrequencyDaily,
    FrequencyKind.eightHours => text.tmFrequencyEightHours,
    FrequencyKind.twelveHours => text.tmFrequencyTwelveHours,
    FrequencyKind.interval => text.tmFrequencyEveryNHours(
      frequency!.intervalHours!,
    ),
    FrequencyKind.prescribed => text.tmFrequencyPrescribed,
    null => raw,
  };
}

/// One bottom sheet style for every regimen choice (dose, frequency, interval
/// and meals), so the caregiver never meets two kinds of picker.
Future<T?> showRegimenSheet<T>(
  BuildContext context, {
  required String title,
  required Widget Function(BuildContext sheetContext) body,
}) => showModalBottomSheet<T>(
  context: context,
  showDragHandle: true,
  isScrollControlled: true,
  backgroundColor: Theme.of(context).colorScheme.surface,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
  ),
  builder: (sheetContext) => SafeArea(
    child: ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.85,
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(title, style: treatmentDialogTitle(sheetContext)),
            ),
            body(sheetContext),
          ],
        ),
      ),
    ),
  ),
);

Widget _option(BuildContext context, String label, VoidCallback onTap) =>
    ListTile(
      title: Text(label, style: treatmentFieldStyle(context)),
      onTap: onTap,
    );

/// Read-only field that opens a sheet on tap; never shows the keyboard.
class _PickerField extends StatelessWidget {
  const _PickerField({
    required this.fieldKey,
    required this.value,
    required this.label,
    required this.hint,
    required this.enabled,
    required this.onPick,
    this.validator,
    this.display,
    this.icon = Icons.keyboard_arrow_down,
  });

  final Key fieldKey;

  /// Stored value; callers rebuild this field when it changes.
  final String value;
  final String label;
  final String hint;
  final bool enabled;
  final VoidCallback onPick;
  final FormFieldValidator<String>? validator;

  /// Visible text for the stored value (for example a localized frequency).
  final String Function(String value)? display;
  final IconData icon;

  @override
  Widget build(BuildContext context) => FormField<String>(
    // A new value restarts the field so a stale error disappears.
    key: ValueKey('${fieldKey}_$value'),
    initialValue: value,
    validator: validator == null ? null : (_) => validator!(value),
    builder: (state) => InkWell(
      key: fieldKey,
      borderRadius: BorderRadius.circular(16),
      onTap: enabled ? onPick : null,
      child: InputDecorator(
        isEmpty: value.isEmpty,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          enabled: enabled,
          errorText: state.errorText,
          errorMaxLines: 4,
          suffixIcon: Icon(icon),
        ),
        child: Text(
          value.isEmpty ? '' : (display?.call(value) ?? value),
          style: treatmentFieldStyle(context),
        ),
      ),
    ),
  );
}

/// Dose chosen from common options or composed in a small modal with half
/// steps and a form (tablets, capsules, drops...). No keyboard involved.
class DoseField extends StatelessWidget {
  const DoseField({
    super.key,
    required this.controller,
    required this.fieldKey,
    this.enabled = true,
  });
  final TextEditingController controller;
  final Key fieldKey;
  final bool enabled;

  Future<void> _pick(BuildContext context) async {
    final text = AppLocalizations.of(context);
    final common = [
      text.tmDoseHalfTablet,
      text.tmDoseTablet,
      text.tmDoseTwoTablets,
      text.tmDoseCapsule,
    ];
    final choice = await showRegimenSheet<String>(
      context,
      title: text.tmDoseSelect,
      body: (sheet) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final dose in common)
            _option(sheet, dose, () => Navigator.pop(sheet, dose)),
          ListTile(
            key: const Key('dose-custom'),
            leading: const Icon(Icons.tune),
            title: Text(text.tmDoseCustom, style: treatmentFieldStyle(sheet)),
            onTap: () => Navigator.pop(sheet, ''),
          ),
        ],
      ),
    );
    if (!context.mounted || choice == null) return;
    if (choice.isNotEmpty) {
      controller.text = choice;
      return;
    }
    final custom = await showRegimenSheet<String>(
      context,
      title: text.tmDoseCustom,
      body: (sheet) => const _CustomDose(),
    );
    if (context.mounted && custom != null) controller.text = custom;
  }

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    return ValueListenableBuilder(
      valueListenable: controller,
      builder: (context, value, _) => _PickerField(
        fieldKey: fieldKey,
        value: value.text,
        label: text.tmDoseShort,
        hint: text.tmDoseSelect,
        enabled: enabled,
        onPick: () => _pick(context),
        validator: (value) =>
            Dosage.tryParse(value ?? '') == null ? text.tmRequiredField : null,
      ),
    );
  }
}

enum _DoseUnit { tablet, capsule, drop, ml, sachet, puff }

class _CustomDose extends StatefulWidget {
  const _CustomDose();
  @override
  State<_CustomDose> createState() => _CustomDoseState();
}

class _CustomDoseState extends State<_CustomDose> {
  /// Amount in half units: 5 means two and a half.
  int _halves = 2;
  _DoseUnit _unit = _DoseUnit.tablet;

  /// Halves only make sense for solid forms that can be split.
  bool get _splittable =>
      _unit == _DoseUnit.tablet || _unit == _DoseUnit.sachet;

  String _amount() {
    final whole = _halves ~/ 2;
    final half = _halves.isOdd;
    if (whole == 0) return '½';
    return half ? '$whole ½' : '$whole';
  }

  String _unitLabel(AppLocalizations text, _DoseUnit unit, int count) =>
      switch (unit) {
        _DoseUnit.tablet => text.tmUnitTablet(count),
        _DoseUnit.capsule => text.tmUnitCapsule(count),
        _DoseUnit.drop => text.tmUnitDrop(count),
        _DoseUnit.ml => text.tmUnitMl,
        _DoseUnit.sachet => text.tmUnitSachet(count),
        _DoseUnit.puff => text.tmUnitPuff(count),
      };

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final count = _halves <= 2 ? 1 : 2;
    final dose = '${_amount()} ${_unitLabel(text, _unit, count)}';
    final step = _splittable ? 1 : 2;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(text.tmDoseAmount, style: treatmentSupportingStyle(context)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton.filledTonal(
                key: const Key('dose-decrease'),
                tooltip: text.tmDoseDecrease,
                onPressed: _halves > step
                    ? () => setState(() => _halves -= step)
                    : null,
                icon: const Icon(Icons.remove),
              ),
              SizedBox(
                width: 120,
                child: Text(
                  _amount(),
                  key: const Key('dose-amount'),
                  textAlign: TextAlign.center,
                  style: treatmentSectionStyle(context).copyWith(fontSize: 28),
                ),
              ),
              IconButton.filledTonal(
                key: const Key('dose-increase'),
                tooltip: text.tmDoseIncrease,
                onPressed: _halves < 40
                    ? () => setState(() => _halves += step)
                    : null,
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(text.tmDoseUnit, style: treatmentSupportingStyle(context)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final unit in _DoseUnit.values)
                ChoiceChip(
                  label: Text(_unitLabel(text, unit, 2)),
                  selected: unit == _unit,
                  selectedColor: scheme.primaryContainer,
                  onSelected: (_) => setState(() {
                    _unit = unit;
                    // Drops, ml, capsules and puffs are counted whole.
                    if (!_splittable && _halves.isOdd) _halves += 1;
                  }),
                ),
            ],
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            key: const Key('dose-apply'),
            onPressed: () => Navigator.pop(context, dose),
            child: Text('${text.tmUnitApply}: $dose'),
          ),
        ],
      ),
    );
  }
}

/// The user selects a supported prescription rather than typing an API label.
/// The controller keeps the localized label; [Frequency] parses both.
class FrequencyField extends StatelessWidget {
  const FrequencyField({
    super.key,
    required this.controller,
    required this.fieldKey,
    this.enabled = true,
  });
  final TextEditingController controller;
  final Key fieldKey;
  final bool enabled;

  Future<void> _pick(BuildContext context) async {
    final text = AppLocalizations.of(context);
    final options = [
      text.tmFrequencyDaily,
      text.tmFrequencyEveryNHours(6),
      text.tmFrequencyEightHours,
      text.tmFrequencyTwelveHours,
    ];
    final choice = await showRegimenSheet<String>(
      context,
      title: text.tmFrequencySelect,
      body: (sheet) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final label in options)
            _option(sheet, label, () => Navigator.pop(sheet, label)),
          ListTile(
            key: const Key('frequency-other-interval'),
            leading: const Icon(Icons.tune),
            title: Text(
              text.tmFrequencyOtherInterval,
              style: treatmentFieldStyle(sheet),
            ),
            onTap: () => Navigator.pop(sheet, ''),
          ),
          _option(
            sheet,
            text.tmFrequencyPrescribed,
            () => Navigator.pop(sheet, text.tmFrequencyPrescribed),
          ),
        ],
      ),
    );
    if (!context.mounted || choice == null) return;
    if (choice.isNotEmpty) {
      controller.text = choice;
      return;
    }
    final hours = await showRegimenSheet<int>(
      context,
      title: text.tmFrequencyIntervalTitle,
      body: (sheet) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        child: Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final hours in Frequency.supportedIntervals)
              ActionChip(
                key: Key('interval-$hours'),
                label: Text(
                  text.tmFrequencyEveryNHours(hours),
                  style: treatmentFieldStyle(sheet),
                ),
                onPressed: () => Navigator.pop(sheet, hours),
              ),
          ],
        ),
      ),
    );
    if (context.mounted && hours != null) {
      controller.text = text.tmFrequencyEveryNHours(hours);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    return ValueListenableBuilder(
      valueListenable: controller,
      builder: (context, value, _) => _PickerField(
        fieldKey: fieldKey,
        value: value.text,
        label: text.tmFrequencyShort,
        hint: text.tmFrequencySelect,
        enabled: enabled,
        display: (value) => frequencyLabel(text, value),
        onPick: () => _pick(context),
        validator: (value) => Frequency.tryParse(value ?? '') == null
            ? text.tmErrInvalidFrequency
            : null,
      ),
    );
  }
}

Future<TimeOfDay?> pickRegimenTime(BuildContext context, TimeOfDay initial) =>
    showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: Theme(
          data: treatmentDialogTheme(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              backgroundColor: Theme.of(context).colorScheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              dialBackgroundColor: Theme.of(context)
                  .colorScheme
                  .surfaceContainerLow,
              dialHandColor: Theme.of(context).colorScheme.primary,
              hourMinuteShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              helpTextStyle: treatmentDialogTitle(context)
                  .copyWith(fontSize: 20),
            ),
          ),
          child: child!,
        ),
      ),
    );

List<ClockTime> _parseTimes(String value) =>
    value
        .split(',')
        .map(ClockTime.tryParse)
        .whereType<ClockTime>()
        .toSet()
        .toList()
      ..sort();

/// For an interval or a single daily dose: the caregiver picks the first
/// dose and every other time of the day is derived (08:00 every 6 hours
/// gives 08:00, 14:00, 20:00 and 02:00). The [controller] keeps the
/// normalized comma separated times the use cases validate.
class StartTimeField extends StatelessWidget {
  const StartTimeField({
    super.key,
    required this.controller,
    required this.frequency,
    required this.fieldKey,
    this.enabled = true,
  });
  final TextEditingController controller;
  final Frequency frequency;
  final Key fieldKey;
  final bool enabled;

  /// The stored times are sorted, so the start shown is the first dose from
  /// 05:00 on (a day usually starts there: 08:00 rather than 02:00).
  ClockTime? _start(List<ClockTime> times) {
    if (times.isEmpty) return null;
    for (final time in times) {
      if (time.hour >= 5) return time;
    }
    return times.first;
  }

  static String _format(int minutes) =>
      '${(minutes ~/ 60).toString().padLeft(2, '0')}:'
      '${(minutes % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    final once = frequency.kind == FrequencyKind.onceDaily;
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final times = _parseTimes(value.text);
        final valid =
            times.isNotEmpty &&
            frequency.matchesMinutes(times.map((t) => t.hour * 60 + t.minute));
        final start = valid ? _start(times) : null;
        Future<void> pick() async {
          final selected = await pickRegimenTime(
            context,
            start == null
                ? const TimeOfDay(hour: 8, minute: 0)
                : TimeOfDay(hour: start.hour, minute: start.minute),
          );
          if (selected == null) return;
          controller.text = frequency
              .minutesFrom(selected.hour * 60 + selected.minute)
              .map(_format)
              .join(',');
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _PickerField(
              fieldKey: fieldKey,
              value: start?.toString() ?? '',
              label: once ? text.tmDoseTime : text.tmStartTime,
              hint: text.tmScheduleAddTime,
              enabled: enabled,
              icon: Icons.schedule,
              onPick: pick,
              validator: (_) => valid ? null : text.tmErrEmptySchedule,
            ),
            if (!once) ...[
              const SizedBox(height: 6),
              Text(
                text.tmStartTimeHint,
                style: treatmentSupportingStyle(context).copyWith(fontSize: 12),
              ),
            ],
            if (valid && !once) ...[
              const SizedBox(height: 10),
              Text(
                text.tmDosesPerDay(times.length),
                style: treatmentFieldStyle(context)
                    .copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final minutes in frequency.minutesFrom(
                    start!.hour * 60 + start.minute,
                  ))
                    Chip(
                      label: Text(
                        _format(minutes),
                        style: treatmentFieldStyle(context),
                      ),
                      backgroundColor: Theme.of(context).colorScheme.surface,
                      shape: const StadiumBorder(),
                      side: BorderSide(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                ],
              ),
            ],
          ],
        );
      },
    );
  }
}

/// Manual times for "Según indicación médica": each one is added with the
/// clock dialog and shown as a removable chip.
class ScheduleTimeField extends StatelessWidget {
  const ScheduleTimeField({
    super.key,
    required this.controller,
    required this.frequency,
    required this.fieldKey,
    this.enabled = true,
  });
  final TextEditingController controller;
  final TextEditingController frequency;
  final Key fieldKey;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final times = _parseTimes(value.text);
        final kind = Frequency.tryParse(frequency.text);
        Future<void> add() async {
          final selected = await pickRegimenTime(
            context,
            const TimeOfDay(hour: 8, minute: 0),
          );
          if (!context.mounted || selected == null) return;
          final newTime = ClockTime.tryParse(
            '${selected.hour}:${selected.minute.toString().padLeft(2, '0')}',
          )!;
          final next = _parseTimes(controller.text).toSet()..add(newTime);
          controller.text = (next.toList()..sort()).join(',');
        }

        return FormField<String>(
          key: ValueKey('${fieldKey}_${value.text}'),
          initialValue: value.text,
          validator: (_) {
            final raw = controller.text.trim();
            if (raw.isEmpty) return text.tmErrEmptySchedule;
            if (raw.split(',').any((v) => ClockTime.tryParse(v) == null)) {
              return text.tmErrInvalidTime;
            }
            if (kind != null &&
                !kind.matchesMinutes(
                  _parseTimes(raw).map((t) => t.hour * 60 + t.minute),
                )) {
              return text.tmScheduleMismatch;
            }
            return null;
          },
          builder: (state) => Column(
            key: fieldKey,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                text.tmSchedulePickerLabel,
                style: treatmentSupportingStyle(context),
              ),
              const SizedBox(height: 4),
              Text(
                text.tmScheduleDailyHint,
                style: treatmentSupportingStyle(context).copyWith(fontSize: 12),
              ),
              if (times.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final time in times)
                      InputChip(
                        label: Text(
                          '$time',
                          style: treatmentFieldStyle(context),
                        ),
                        backgroundColor: Theme.of(context).colorScheme.surface,
                        shape: const StadiumBorder(),
                        side: BorderSide(
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                        deleteIconColor: Theme.of(context).colorScheme.primary,
                        deleteButtonTooltipMessage:
                            '${text.tmScheduleRemoveTime} $time',
                        onDeleted: enabled
                            ? () => controller.text = (_parseTimes(
                                controller.text,
                              )..remove(time)).join(',')
                            : null,
                      ),
                  ],
                ),
              ],
              if (state.errorText case final error?) ...[
                const SizedBox(height: 6),
                Text(
                  error,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              OutlinedButton.icon(
                key: const Key('add-schedule-time'),
                style: treatmentSecondaryStyle(context),
                onPressed: enabled ? add : null,
                icon: const Icon(Icons.add),
                label: Text(text.tmScheduleAddTime),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Timing relative to meals, chosen in a sheet: one moment (before, with,
/// after) and any of the three meals. It produces a readable sentence such
/// as "Después del desayuno y la cena" that travels in the instructions.
class MealTimingField extends StatelessWidget {
  const MealTimingField({
    super.key,
    required this.controller,
    required this.fieldKey,
    this.enabled = true,
  });
  final TextEditingController controller;
  final Key fieldKey;
  final bool enabled;

  /// True when [line] was produced by this field, so editing a treatment can
  /// separate it from free text.
  static bool isMealLine(AppLocalizations text, String line) {
    final lower = line.toLowerCase();
    return [
          text.tmMealBefore,
          text.tmMealDuring,
          text.tmMealAfter,
        ].any((moment) => lower.startsWith('${moment.toLowerCase()} ')) &&
        [
          text.tmMealBreakfastPhrase,
          text.tmMealLunchPhrase,
          text.tmMealDinnerPhrase,
        ].any((meal) => lower.contains(meal.toLowerCase()));
  }

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    return ValueListenableBuilder(
      valueListenable: controller,
      builder: (context, value, _) => _PickerField(
        fieldKey: fieldKey,
        value: value.text,
        label: text.tmMealsLabel,
        hint: text.tmMealsSelect,
        enabled: enabled,
        icon: Icons.restaurant_outlined,
        onPick: () async {
          final result = await showRegimenSheet<String>(
            context,
            title: text.tmMealsSelect,
            body: (_) => const _MealTiming(),
          );
          if (result != null) controller.text = result;
        },
      ),
    );
  }
}

class _MealTiming extends StatefulWidget {
  const _MealTiming();
  @override
  State<_MealTiming> createState() => _MealTimingState();
}

class _MealTimingState extends State<_MealTiming> {
  int _moment = 2;
  final _meals = <int>{0};

  String _sentence(AppLocalizations text) {
    final moments = [text.tmMealBefore, text.tmMealDuring, text.tmMealAfter];
    final phrases = [
      text.tmMealBreakfastPhrase,
      text.tmMealLunchPhrase,
      text.tmMealDinnerPhrase,
    ];
    final meals = [for (final i in (_meals.toList()..sort())) phrases[i]];
    final joined = meals.length < 2
        ? meals.join()
        : '${meals.sublist(0, meals.length - 1).join(', ')} '
              '${text.tmMealAnd} ${meals.last}';
    // Spanish contraction: "de el desayuno" is written "del desayuno".
    return '${moments[_moment]} $joined'.replaceAll(' de el ', ' del ');
  }

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final moments = [text.tmMealBefore, text.tmMealDuring, text.tmMealAfter];
    final meals = [text.tmMealBreakfast, text.tmMealLunch, text.tmMealDinner];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SegmentedButton<int>(
            showSelectedIcon: false,
            segments: [
              for (var i = 0; i < moments.length; i++)
                ButtonSegment(value: i, label: Text(moments[i])),
            ],
            selected: {_moment},
            onSelectionChanged: (value) =>
                setState(() => _moment = value.single),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < meals.length; i++)
                FilterChip(
                  key: Key('meal-$i'),
                  label: Text(meals[i]),
                  selected: _meals.contains(i),
                  selectedColor: scheme.primaryContainer,
                  onSelected: (on) => setState(() {
                    if (on) {
                      _meals.add(i);
                    } else if (_meals.length > 1) {
                      _meals.remove(i);
                    }
                  }),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _sentence(text),
            textAlign: TextAlign.center,
            style: treatmentFieldStyle(context)
                .copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            key: const Key('meals-apply'),
            onPressed: () => Navigator.pop(context, _sentence(text)),
            child: Text(text.tmMealsApply),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, ''),
            child: Text(text.tmMealsClear),
          ),
        ],
      ),
    );
  }
}

/// Dose, frequency, times, meals and extra instructions of one medication,
/// shared by the creation wizard and the regimen editor. The [instructions]
/// controller receives the meal sentence and the free text joined by a line
/// break, which is what the API stores.
class RegimenFields extends StatefulWidget {
  const RegimenFields({
    super.key,
    required this.dose,
    required this.frequency,
    required this.times,
    required this.instructions,
    this.keyPrefix = 'treatment',
    this.enabled = true,
    this.timeZone,
  });

  final TextEditingController dose;
  final TextEditingController frequency;
  final TextEditingController times;
  final TextEditingController instructions;
  final String keyPrefix;
  final bool enabled;
  final String? timeZone;

  @override
  State<RegimenFields> createState() => _RegimenFieldsState();
}

class _RegimenFieldsState extends State<RegimenFields> {
  final _meal = TextEditingController();
  final _extra = TextEditingController();
  bool _split = false;
  String? _lastFrequency;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_split) return;
    _split = true;
    final text = AppLocalizations.of(context);
    final lines = widget.instructions.text.split('\n');
    if (lines.isNotEmpty && MealTimingField.isMealLine(text, lines.first)) {
      _meal.text = lines.first;
      _extra.text = lines.skip(1).join('\n');
    } else {
      _extra.text = widget.instructions.text;
    }
    _meal.addListener(_join);
    _extra.addListener(_join);
    _lastFrequency = widget.frequency.text;
    widget.frequency.addListener(_frequencyChanged);
  }

  void _join() {
    widget.instructions.text = [
      _meal.text.trim(),
      _extra.text.trim(),
    ].where((line) => line.isNotEmpty).join('\n');
  }

  /// A different frequency invalidates times derived for the previous one;
  /// the times section itself also changes (start time or manual list).
  void _frequencyChanged() {
    final now = widget.frequency.text;
    if (now == _lastFrequency) return;
    final before = Frequency.tryParse(_lastFrequency ?? '');
    final after = Frequency.tryParse(now);
    _lastFrequency = now;
    final times = _parseTimes(widget.times.text);
    if (after != null && times.isNotEmpty) {
      if (after.derivesTimes) {
        // Keep the caregiver's start time and derive the new cycle from it.
        final first = times.firstWhere(
          (t) => t.hour >= 5,
          orElse: () => times.first,
        );
        widget.times.text = after
            .minutesFrom(first.hour * 60 + first.minute)
            .map(StartTimeField._format)
            .join(',');
      } else if (before?.derivesTimes ?? false) {
        widget.times.clear();
      }
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.frequency.removeListener(_frequencyChanged);
    _meal.dispose();
    _extra.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    final prefix = widget.keyPrefix;
    final frequency = Frequency.tryParse(widget.frequency.text);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DoseField(
          fieldKey: Key('$prefix-dose'),
          controller: widget.dose,
          enabled: widget.enabled,
        ),
        const SizedBox(height: 16),
        FrequencyField(
          fieldKey: Key('$prefix-frequency'),
          controller: widget.frequency,
          enabled: widget.enabled,
        ),
        if (frequency != null) ...[
          const SizedBox(height: 16),
          if (frequency.derivesTimes)
            StartTimeField(
              fieldKey: Key('$prefix-times'),
              controller: widget.times,
              frequency: frequency,
              enabled: widget.enabled,
            )
          else
            ScheduleTimeField(
              fieldKey: Key('$prefix-times'),
              controller: widget.times,
              frequency: widget.frequency,
              enabled: widget.enabled,
            ),
          if (widget.timeZone case final zone?) ...[
            const SizedBox(height: 8),
            Text(
              '${text.tmTimeZone}: $zone',
              style: treatmentSupportingStyle(context).copyWith(fontSize: 12),
            ),
          ],
        ],
        const SizedBox(height: 16),
        MealTimingField(
          fieldKey: Key('$prefix-meals'),
          controller: _meal,
          enabled: widget.enabled,
        ),
        const SizedBox(height: 16),
        TextFormField(
          key: Key('$prefix-instructions'),
          controller: _extra,
          enabled: widget.enabled,
          style: treatmentFieldStyle(context),
          maxLength: 400,
          minLines: 1,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: text.tmExtraInstructions,
            hintText: text.tmInstructions,
          ),
        ),
      ],
    );
  }
}

/// Minutes to wait before alerting the family about an unconfirmed dose,
/// chosen in the same kind of sheet as the rest of the regimen. Empty keeps
/// the system default.
class FollowUpField extends StatelessWidget {
  const FollowUpField({
    super.key,
    required this.controller,
    required this.fieldKey,
    this.enabled = true,
  });
  final TextEditingController controller;
  final Key fieldKey;
  final bool enabled;

  static const options = [5, 10, 15, 30, 60, 120];

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    String label(String value) => value.isEmpty
        ? text.tmDefaultFollowUp
        : text.tmFollowUpMinutes(int.tryParse(value) ?? 0);
    return ValueListenableBuilder(
      valueListenable: controller,
      builder: (context, value, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PickerField(
            fieldKey: fieldKey,
            value: value.text,
            label: text.tmFollowUpShort,
            hint: text.tmDefaultFollowUp,
            enabled: enabled,
            icon: Icons.notifications_none,
            display: label,
            onPick: () async {
              final choice = await showRegimenSheet<String>(
                context,
                title: text.tmFollowUpShort,
                body: (sheet) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final option in ['', for (final m in options) '$m'])
                      _option(sheet, label(option), () {
                        Navigator.pop(sheet, option);
                      }),
                  ],
                ),
              );
              if (choice != null) controller.text = choice;
            },
          ),
          const SizedBox(height: 8),
          Text(
            text.tmFollowUpHelp,
            style: treatmentSupportingStyle(context).copyWith(fontSize: 12),
          ),
        ],
      ),
    );
  }
}
