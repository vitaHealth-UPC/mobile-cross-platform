import 'package:flutter/material.dart';

import '../theme/tata_colors.dart';

/// Tone of a [StatusNotice]: a refused action or a step that can be repeated.
enum NoticeTone { error, warning }

/// Figma 563:2162, 563:2208 and 563:2254: a short title that names the problem
/// and a line that says what to do next. Read aloud when it appears.
class StatusNotice extends StatelessWidget {
  const StatusNotice({
    super.key,
    required this.body,
    this.title,
    this.tone = NoticeTone.error,
  });

  final String? title;
  final String body;
  final NoticeTone tone;

  static const _warningSurface = Color(0xFFFFF4E2);
  static const _warningText = Color(0xFF8A5A00);

  /// Darker than the Figma grey so small text keeps 4.5:1 on both surfaces.
  static const _bodyText = Color(0xFF4F5B70);

  @override
  Widget build(BuildContext context) {
    final (surface, accent) = switch (tone) {
      NoticeTone.error => (TataColors.errorSurface, TataColors.errorText),
      NoticeTone.warning => (_warningSurface, _warningText),
    };
    return Semantics(
      liveRegion: true,
      container: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title case final heading?) ...[
              Text(
                heading,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: accent,
                ),
              ),
              const SizedBox(height: 4),
            ],
            Text(
              body,
              style: TextStyle(
                fontSize: 13,
                height: 1.35,
                color: title == null ? accent : _bodyText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
