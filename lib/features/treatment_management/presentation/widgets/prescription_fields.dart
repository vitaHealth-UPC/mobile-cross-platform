import 'package:flutter/material.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/value_objects/administration_schedule.dart';
import '../../domain/value_objects/regimen_text.dart';

String frequencyLabel(AppLocalizations text, String raw) =>
    switch (Frequency.tryParse(raw)?.kind) {
      FrequencyKind.daily => text.tmFrequencyEveryDay,
      FrequencyKind.onceDaily => text.tmFrequencyDaily,
      FrequencyKind.eightHours => text.tmFrequencyEightHours,
      FrequencyKind.twelveHours => text.tmFrequencyTwelveHours,
      FrequencyKind.prescribed => text.tmFrequencyPrescribed,
      null => raw,
    };

/// The user selects a supported prescription rather than typing an API label.
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

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    final labels = [
      text.tmFrequencyDaily,
      text.tmFrequencyEightHours,
      text.tmFrequencyTwelveHours,
      text.tmFrequencyEveryDay,
      text.tmFrequencyPrescribed,
    ];
    void choose(String value) => controller.text = value;
    return TextFormField(
      key: fieldKey,
      controller: controller,
      readOnly: true,
      enabled: enabled,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: InputDecoration(
        labelText: text.tmFrequencyShort,
        hintText: text.tmFrequencySelect,
        suffixIcon: PopupMenuButton<String>(
          enabled: enabled,
          tooltip: text.tmFrequencySelect,
          icon: const Icon(Icons.keyboard_arrow_down),
          onSelected: choose,
          itemBuilder: (_) => [
            for (final label in labels)
              PopupMenuItem(value: label, child: Text(label)),
          ],
        ),
      ),
      onTap: enabled
          ? () async {
              final selected = await showModalBottomSheet<String>(
                context: context,
                showDragHandle: true,
                builder: (context) => SafeArea(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          text.tmFrequencySelect,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      for (final label in labels)
                        ListTile(
                          title: Text(label),
                          onTap: () => Navigator.pop(context, label),
                        ),
                    ],
                  ),
                ),
              );
              if (context.mounted && selected != null) choose(selected);
            }
          : null,
      validator: (value) => Frequency.tryParse(value ?? '') == null
          ? text.tmErrInvalidFrequency
          : null,
    );
  }
}

/// A calendar-style clock dialog adds a distinct local time. The text controller
/// is the normalized representation for the existing application use cases.
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

  List<ClockTime> _times(String value) =>
      value
          .split(',')
          .map(ClockTime.tryParse)
          .whereType<ClockTime>()
          .toSet()
          .toList()
        ..sort();

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final times = _times(value.text);
        final kind = Frequency.tryParse(frequency.text);
        final hint = switch (kind?.kind) {
          FrequencyKind.onceDaily => text.tmScheduleOnceHint,
          FrequencyKind.eightHours => text.tmScheduleEightHint,
          FrequencyKind.twelveHours => text.tmScheduleTwelveHint,
          _ => text.tmScheduleDailyHint,
        };
        Future<void> add() async {
          final selected = await showTimePicker(
            context: context,
            initialTime: const TimeOfDay(hour: 8, minute: 0),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(alwaysUse24HourFormat: true),
              child: child!,
            ),
          );
          if (!context.mounted || selected == null) return;
          final newTime = ClockTime.tryParse(
            '${selected.hour}:${selected.minute.toString().padLeft(2, '0')}',
          )!;
          final next = _times(controller.text).toSet()..add(newTime);
          controller.text = (next.toList()..sort()).join(',');
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              key: fieldKey,
              controller: controller,
              readOnly: true,
              enabled: enabled,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              onTap: enabled ? add : null,
              decoration: InputDecoration(
                labelText: text.tmSchedulePickerLabel,
                hintText: text.tmScheduleAddTime,
                helperText: hint,
                helperMaxLines: 4,
                errorMaxLines: 4,
                suffixIcon: IconButton(
                  tooltip: text.tmScheduleAddTime,
                  onPressed: enabled ? add : null,
                  icon: const Icon(Icons.schedule),
                ),
              ),
              validator: (value) {
                final raw = value?.trim() ?? '';
                if (raw.isEmpty) return text.tmErrEmptySchedule;
                if (raw.split(',').any((v) => ClockTime.tryParse(v) == null)) {
                  return text.tmErrInvalidTime;
                }
                if (kind != null &&
                    !kind.matchesMinutes(
                      _times(raw).map((t) => t.hour * 60 + t.minute),
                    )) {
                  return text.tmScheduleMismatch;
                }
                return null;
              },
            ),
            if (times.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final time in times)
                    InputChip(
                      label: Text('$time'),
                      deleteButtonTooltipMessage:
                          '${text.tmScheduleRemoveTime} $time',
                      onDeleted: enabled
                          ? () => controller.text = (_times(
                              controller.text,
                            )..remove(time)).join(',')
                          : null,
                    ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: enabled ? add : null,
              icon: const Icon(Icons.add),
              label: Text(text.tmScheduleAddTime),
            ),
          ],
        );
      },
    );
  }
}

/// Optional shortcuts never preselect a dose or substitute a prescription.
Widget prescriptionOptions({
  required String tooltip,
  required List<String> options,
  required TextEditingController controller,
  bool enabled = true,
  bool append = false,
}) => PopupMenuButton<String>(
  tooltip: tooltip,
  enabled: enabled,
  icon: const Icon(Icons.arrow_drop_down),
  itemBuilder: (_) => [
    for (final option in options)
      PopupMenuItem(value: option, child: Text(option)),
  ],
  onSelected: (value) {
    if (append && controller.text.trim().isNotEmpty) {
      final current = controller.text.trim();
      if (!current.split('\n').contains(value)) {
        controller.text = '$current\n$value';
      }
    } else {
      controller.text = value;
    }
  },
);

Widget reminderOptions(
  AppLocalizations text,
  TextEditingController controller, {
  bool enabled = true,
}) => PopupMenuButton<String>(
  tooltip: text.tmChooseReminder,
  enabled: enabled,
  onSelected: (value) => controller.text = value,
  itemBuilder: (_) => [
    PopupMenuItem(value: '', child: Text(text.tmDefaultFollowUp)),
    for (final minutes in [0, 5, 10, 15, 30, 60, 120])
      PopupMenuItem(
        value: '$minutes',
        child: Text('$minutes ${text.tmMinutesLabel}'),
      ),
  ],
);
