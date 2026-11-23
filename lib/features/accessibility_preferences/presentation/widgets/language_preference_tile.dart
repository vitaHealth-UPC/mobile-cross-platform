import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/value_objects/accessibility_preferences.dart';

/// Native language control; the owner stores the selection and rebuilds the app.
class LanguagePreferenceTile extends StatelessWidget {
  const LanguagePreferenceTile({
    super.key,
    required this.language,
    required this.onChanged,
  });

  final AppLanguage language;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final normal =
        Theme.of(context).brightness == Brightness.light &&
        !MediaQuery.highContrastOf(context);
    final stacked = MediaQuery.textScalerOf(context).scale(13) > 16;
    final selector = OutlinedButton(
      key: const Key('language-selector'),
      onPressed: onChanged,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(118, 44),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        backgroundColor: normal
            ? const Color(0xFFF2F0FF)
            : colors.surfaceContainerHighest,
        foregroundColor: colors.primary,
        side: BorderSide(
          color: normal ? const Color(0xFFA694FF) : colors.outline,
        ),
        shape: const StadiumBorder(),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.chevron_left, size: 14),
          const SizedBox(width: 4),
          Text(
            language.displayName,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right, size: 14),
        ],
      ),
    );
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      leading: ExcludeSemantics(
        child: CircleAvatar(
          radius: 16,
          backgroundColor: normal
              ? const Color(0xFFF0EBFF)
              : colors.surfaceContainerHighest,
          child: SvgPicture.asset(
            'assets/icons/language_globe.svg',
            colorFilter: normal
                ? null
                : ColorFilter.mode(colors.onSurface, BlendMode.srcIn),
          ),
        ),
      ),
      title: Text(
        text.pfLanguage,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            text.pfLanguageHint,
            style: TextStyle(
              fontSize: 10,
              color: colors.onSurfaceVariant,
              letterSpacing: 0,
            ),
          ),
          if (stacked) ...[const SizedBox(height: 8), selector],
        ],
      ),
      trailing: stacked ? null : selector,
      onTap: onChanged,
    );
  }
}
