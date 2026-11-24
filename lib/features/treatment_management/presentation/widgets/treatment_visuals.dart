import 'package:flutter/material.dart';

import '../../../../shared/presentation/theme/tata_colors.dart';
import '../../../../shared/presentation/theme/tata_typography.dart';

/// Shared visual roles for the caregiver medication and treatment flows.
class TreatmentHeader extends StatelessWidget {
  const TreatmentHeader({
    super.key,
    required this.title,
    required this.backLabel,
    required this.onBack,
  });
  final String title;
  final String backLabel;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      IconButton(
        tooltip: backLabel,
        onPressed: onBack,
        icon: Icon(
          Icons.chevron_left,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
      Expanded(
        child: Semantics(
          header: true,
          child: Text(
            title,
            style: TataTypography.heading.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      ),
    ],
  );
}

class TreatmentSurface extends StatelessWidget {
  const TreatmentSurface({
    super.key,
    required this.child,
    this.color,
    this.padding = const EdgeInsets.all(16),
  });
  final Widget child;
  final Color? color;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? theme.colorScheme.surface,
        border: Border.all(
          color: theme.brightness == Brightness.light
              ? TataColors.softBorder
              : theme.colorScheme.outlineVariant,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x141A2138),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

ButtonStyle treatmentSecondaryStyle(BuildContext context) {
  final scheme = Theme.of(context).colorScheme;
  return OutlinedButton.styleFrom(
    backgroundColor: Theme.of(context).brightness == Brightness.light
        ? TataColors.lavender
        : scheme.secondaryContainer,
    foregroundColor: scheme.primary,
    side: BorderSide(color: scheme.outlineVariant),
    shape: const StadiumBorder(),
    minimumSize: const Size(0, 44),
    textStyle: const TextStyle(
      fontFamily: 'Inter',
      fontSize: 14,
      fontWeight: FontWeight.w600,
    ),
  );
}

TextStyle treatmentFieldStyle(BuildContext context) => TextStyle(
  fontFamily: 'Inter',
  fontSize: 14,
  color: Theme.of(context).colorScheme.onSurface,
);

TextStyle treatmentSectionStyle(BuildContext context) => TextStyle(
  fontFamily: 'Inter',
  fontSize: 18,
  fontWeight: FontWeight.w600,
  color: Theme.of(context).colorScheme.onSurface,
);

TextStyle treatmentSupportingStyle(BuildContext context) => TextStyle(
  fontFamily: 'Inter',
  fontSize: 14,
  height: 1.5,
  color: Theme.of(context).colorScheme.onSurfaceVariant,
);

TextStyle treatmentDialogTitle(BuildContext context) => TataTypography.heading
    .copyWith(fontSize: 24, color: Theme.of(context).colorScheme.onSurface);

ThemeData treatmentDialogTheme(BuildContext context) {
  final theme = Theme.of(context);
  final scheme = theme.colorScheme;
  return theme.copyWith(
    dialogTheme: DialogThemeData(
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      titleTextStyle: treatmentDialogTitle(context),
      contentTextStyle: treatmentSupportingStyle(context),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: scheme.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      textStyle: treatmentFieldStyle(context),
    ),
  );
}

/// Inline acknowledgment, shown only after the mutation has succeeded.
class TreatmentNotice extends StatelessWidget {
  const TreatmentNotice({
    super.key,
    required this.message,
    this.body,
    this.warning = false,
  });
  final String message;
  final String? body;
  final bool warning;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final surface = dark
        ? Theme.of(context).colorScheme.secondaryContainer
        : warning
        ? const Color(0xFFFFF5DB)
        : TataColors.mint;
    final accent = dark
        ? Theme.of(context).colorScheme.onSecondaryContainer
        : warning
        ? const Color(0xFF8A5A00)
        : const Color(0xFF2E6E45);
    return Semantics(
      liveRegion: true,
      container: true,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              warning ? Icons.info_outline : Icons.check_circle_outline,
              color: accent,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: accent,
                    ),
                  ),
                  if (body case final description?) ...[
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        height: 1.4,
                        color: accent,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
