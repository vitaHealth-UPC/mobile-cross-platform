import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/presentation/theme/tata_colors.dart';
import '../../../../shared/presentation/widgets/initials_avatar.dart';
import '../../application/readmodels/monitoring_readmodels.dart';
import '../../domain/entities/notes.dart';
import 'monitoring_widgets.dart';

const _secondaryText = Color(0xFF637087);

/// Profile confirmed by the same authorized follow-up that supplied the notes.
class FollowUpPersonCard extends StatelessWidget {
  const FollowUpPersonCard({
    super.key,
    required this.person,
    required this.now,
  });
  final MonitoredPerson person;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    final age = person.ageAt(now);
    final badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F7EB),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        text.fmPersonActive,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Color(0xFF3D7A52),
        ),
      ),
    );
    return MonitoringCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          InitialsAvatar(name: person.fullName, size: 52),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  person.fullName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  age == null
                      ? text.fmPersonLinkActive
                      : text.fmPersonAgeActive(age),
                  style: const TextStyle(fontSize: 11, color: _secondaryText),
                ),
                if (MediaQuery.textScalerOf(context).scale(11) > 14) ...[
                  const SizedBox(height: 8),
                  badge,
                ],
              ],
            ),
          ),
          if (MediaQuery.textScalerOf(context).scale(11) <= 14) ...[
            const SizedBox(width: 8),
            badge,
          ],
        ],
      ),
    );
  }
}

/// A visual timeline of the original note text, without inferred categories or authors.
class FollowUpNoteCard extends StatelessWidget {
  const FollowUpNoteCard({
    super.key,
    required this.note,
    required this.now,
    required this.index,
  });
  final FollowUpNote note;
  final DateTime now;
  final int index;

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    final lines = note.text.replaceAll('\r\n', '\n').split('\n');
    final hasHeading =
        lines.length > 1 &&
        lines.first.trim().isNotEmpty &&
        lines.first.length <= 100 &&
        lines.skip(1).join('\n').trim().isNotEmpty;
    final title = hasHeading ? lines.first : text.fmFollowUpNoteTitle;
    final body = hasHeading ? lines.skip(1).join('\n').trim() : note.text;
    final at = note.recordedAt.toLocal();
    final today = DateUtils.dateOnly(now.toLocal());
    final day = DateUtils.dateOnly(at);
    final yesterday = DateTime(today.year, today.month, today.day - 1);
    final date = day == today
        ? text.pnToday
        : day == yesterday
        ? text.pnYesterday
        : DateFormat.yMMMd(Localizations.localeOf(context).toLanguageTag())
              .format(at);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: index == 0
            ? const Color(0xFFF0EBFF)
            : index.isOdd
            ? Colors.white
            : const Color(0xFFE8F5FC),
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
          if (index == 0) ...[
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
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  body,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.25,
                    color: _secondaryText,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '$date - ${text.fmNotesAuthorYou}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: TataColors.primary,
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
