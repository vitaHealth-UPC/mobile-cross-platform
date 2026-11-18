import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/presentation/theme/tata_colors.dart';
import '../../domain/entities/notes.dart';
import '../../domain/value_objects/note_values.dart';

/// Read-only note with a local calendar label and text that grows without clipping.
class PersonalNoteCard extends StatelessWidget {
  const PersonalNoteCard({
    super.key,
    required this.note,
    required this.now,
    this.highlight = false,
    this.blue = false,
  });
  final PersonalNote note;
  final DateTime now;
  final bool highlight;
  final bool blue;

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final at = note.recordedAt.toLocal();
    final today = DateUtils.dateOnly(now.toLocal());
    final day = DateUtils.dateOnly(at);
    final yesterday = DateTime(today.year, today.month, today.day - 1);
    String label;
    if (day == today) {
      label = text.pnToday;
    } else if (day == yesterday) {
      label = text.pnYesterday;
    } else if (day.isBefore(today) &&
        !day.isBefore(DateTime(today.year, today.month, today.day - 6))) {
      label = DateFormat.E(locale).format(at);
    } else {
      label = DateFormat.yMMMd(locale).format(at);
    }
    return Semantics(
      label: note.category == PersonalNoteCategory.medication
          ? text.pnMedications
          : text.pnRoutine,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: highlight
              ? const Color(0xFFF0EBFF)
              : blue
              ? const Color(0xFFE8F5FC)
              : Colors.white,
          border: Border.all(color: const Color(0xFFE3E3F0)),
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0F1F2645),
              blurRadius: 12,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (highlight) ...[
              const ExcludeSemantics(
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: Color(0xFFDBD2FF),
                  child: Icon(Icons.circle, size: 6, color: TataColors.primary),
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    note.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: TataColors.ink,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    note.text,
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.35,
                      color: Color(0xFF5B6475),
                    ),
                  ),
                  SizedBox(height: highlight ? 20 : 12),
                  Text(
                    text.pnRecordedAt(
                      label,
                      DateFormat('h:mm a', locale).format(at),
                    ),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: TataColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
